import 'dart:typed_data';

import 'package:biometric_signature/biometric_signature.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:shared/shared.dart';

/// Az aláíró kulcs aliasa a Keystore-ban (H5, K1).
const String signingKeyAlias = 'foretack-web';

/// A csendes eszközkulcs aliasa a Keystore-ban (K1).
const String deviceKeyAlias = 'foretack-device';

/// A webes kulcsműveletek a `biometric_signature` fölött (ADR 0051
/// Addendum 1 H5, Addendum 8 V4).
///
/// Mindkét kulcs P-256 (`SignatureType.ecdsa`), nem exportálható. Az
/// aláíró kulcs minden aláíráshoz friss ujjlenyomatot kér, PIN nélkül; egy
/// új ujjlenyomat felvétele nem érvényteleníti (felhasználói döntés). A
/// kulcs és az aláírás nyers DER-ként jön (`raw`), így nincs base64-kör.
WebKeyOperations biometricWebKeyOperations([BiometricSignature? plugin]) {
  final signature = plugin ?? BiometricSignature();
  return WebKeyOperations(
    createKey: (role) => _createKey(signature, role),
    signWithBiometrics: (message, prompt) =>
        _signWithBiometrics(signature, message, prompt),
    signSilently: (message) => _signSilently(signature, message),
    deleteKeys: () => _deleteKeys(signature),
  );
}

Future<Result<Uint8List, KeyOperationFailure>> _createKey(
  BiometricSignature plugin,
  WebKeyRole role,
) async {
  final isSigning = role == WebKeyRole.signing;
  // Ujjlenyomat nélkül a Keystore egy általános hibával utasítaná el az
  // aláíró kulcsot; így a felhasználó a valódi okot látja (V4).
  if (isSigning && !await _hasEnrolledBiometrics(plugin)) {
    return const Err(KeyOperationFailure.unavailable);
  }
  final result = await plugin.createKeys(
    keyAlias: isSigning ? signingKeyAlias : deviceKeyAlias,
    config: CreateKeysConfig(
      signatureType: SignatureType.ecdsa,
      // A létrehozás nem kér ujjlenyomatot; az első aláírás kéri (H5).
      enforceBiometric: false,
      setInvalidatedByBiometricEnrollment: false,
      useDeviceCredentials: false,
      requireAuthentication: isSigning,
    ),
    keyFormat: KeyFormat.raw,
  );
  final publicKey = result.publicKeyBytes;
  if (publicKey != null && _isSuccess(result.code)) return Ok(publicKey);
  return Err(keyOperationFailureOf(result.code));
}

Future<bool> _hasEnrolledBiometrics(BiometricSignature plugin) async {
  final availability = await plugin.biometricAuthAvailable();
  return (availability.canAuthenticate ?? false) &&
      (availability.hasEnrolledBiometrics ?? false);
}

Future<Result<Uint8List, KeyOperationFailure>> _signWithBiometrics(
  BiometricSignature plugin,
  Uint8List message,
  BiometricPromptText prompt,
) async {
  final result = await plugin.createSignatureFromBytes(
    payload: message,
    keyAlias: signingKeyAlias,
    config: CreateSignatureConfig(
      promptSubtitle: prompt.subtitle,
      cancelButtonText: prompt.cancel,
      allowDeviceCredentials: false,
    ),
    signatureFormat: SignatureFormat.raw,
    promptMessage: prompt.title,
  );
  return _signatureOf(result);
}

Future<Result<Uint8List, KeyOperationFailure>> _signSilently(
  BiometricSignature plugin,
  Uint8List message,
) async {
  // A kulcsnak nincs hitelesítési követelménye, a plugin ablak nélkül ír
  // alá (K1).
  final result = await plugin.createSignatureFromBytes(
    payload: message,
    keyAlias: deviceKeyAlias,
    signatureFormat: SignatureFormat.raw,
  );
  return _signatureOf(result);
}

Future<void> _deleteKeys(BiometricSignature plugin) async {
  await plugin.deleteKeys(keyAlias: signingKeyAlias);
  await plugin.deleteKeys(keyAlias: deviceKeyAlias);
}

Result<Uint8List, KeyOperationFailure> _signatureOf(SignatureResult result) {
  final signature = result.signatureBytes;
  if (signature != null && _isSuccess(result.code)) return Ok(signature);
  return Err(keyOperationFailureOf(result.code));
}

bool _isSuccess(BiometricError? code) =>
    code == null || code == BiometricError.success;

/// A plugin hibakódja → [KeyOperationFailure].
///
/// A rendszer által megszakított ablak (pl. képernyő-kikapcsolás) is
/// elvetésnek számít; a nem kezelt kódok (a plugin újabb verzióiban is
/// bővülhetnek) általános hibák.
KeyOperationFailure keyOperationFailureOf(BiometricError? code) =>
    switch (code) {
      BiometricError.userCanceled ||
      BiometricError.systemCanceled => KeyOperationFailure.canceled,
      BiometricError.keyNotFound ||
      BiometricError.keyInvalidated => KeyOperationFailure.keyMissing,
      BiometricError.notAvailable ||
      BiometricError.notEnrolled ||
      BiometricError.passcodeNotSet => KeyOperationFailure.unavailable,
      BiometricError.lockedOut ||
      BiometricError.lockedOutPermanent => KeyOperationFailure.lockedOut,
      _ => KeyOperationFailure.failed,
    };
