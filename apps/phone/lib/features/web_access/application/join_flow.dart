import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/enrollment_flow.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/device_identity.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy fiók nélküli telefon csatlakozási kérelme (ADR 0051 D3, Addendum 8
/// V9, Addendum 9 X2).
///
/// A név előbb a vázlatba kerül, hogy egy lejárt QR után ne kelljen újra
/// beírni; utána két új kulcs, ujjlenyomatos aláírás és a beküldés jön.
/// A függő kérelem csak a sikeres válasz után kerül a tárba, és ekkor a
/// vázlat törlődik.
class JoinFlow {
  /// Folyamat a [_clientFor] kliensekkel, a [_keys] kulcsműveletekkel, a
  /// [_readIdentity] telefonadatokkal; a kérelmet a [_savePendingJoin]
  /// menti, a nevet a [_rememberName] őrzi meg és a [_forgetName] dobja el.
  JoinFlow({
    required WebAccessClientFor clientFor,
    required WebKeyOperations keys,
    required ReadDeviceIdentity readIdentity,
    required Future<void> Function(PendingJoin pending) savePendingJoin,
    required void Function(String name) rememberName,
    required void Function() forgetName,
  }) : _clientFor = clientFor,
       _keys = keys,
       _readIdentity = readIdentity,
       _savePendingJoin = savePendingJoin,
       _rememberName = rememberName,
       _forgetName = forgetName;

  final WebAccessClientFor _clientFor;
  final WebKeyOperations _keys;
  final ReadDeviceIdentity _readIdentity;
  final Future<void> Function(PendingJoin pending) _savePendingJoin;
  final void Function(String name) _rememberName;
  final void Function() _forgetName;

  /// Csatlakozási kérelem a [payload] belépési kéréshez a [name] névvel;
  /// a [prompt] az ujjlenyomat-ablak szövege (H6).
  ///
  /// A [name]-nek át kell mennie a `normalizeDisplayName`-en: a képernyő
  /// addig nem engedi a küldést, ezért egy rossz név programozói hiba.
  Future<Result<PendingJoin, WebAccessError>> run(
    LoginQrPayload payload, {
    required String name,
    required BiometricPromptText prompt,
  }) async {
    final normalized = normalizeDisplayName(name);
    if (normalized == null) {
      throw ArgumentError.value(name, 'name', 'not a display name');
    }
    _rememberName(normalized);
    await _keys.deleteKeys();
    final Uint8List publicKey;
    switch (await _keys.createKey(WebKeyRole.signing)) {
      case Ok(:final value):
        publicKey = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    final Uint8List deviceKey;
    switch (await _keys.createKey(WebKeyRole.device)) {
      case Ok(:final value):
        deviceKey = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    final message = joinRequestMessage(
      origin: payload.origin,
      requestId: payload.requestId,
      challenge: payload.challenge,
      name: normalized,
      publicKey: publicKey,
      deviceKey: deviceKey,
    );
    final Uint8List signature;
    switch (await _keys.signWithBiometrics(message, prompt)) {
      case Ok(:final value):
        signature = value;
      case Err(:final error):
        return Err(KeyOperationFailed(error));
    }
    final identity = await _readIdentity();
    final request = JoinRequest(
      requestId: payload.requestId,
      challenge: payload.challenge,
      name: normalized,
      deviceName: identity.deviceName,
      model: identity.model,
      publicKey: publicKey,
      deviceKey: deviceKey,
      signature: signature,
    );
    switch (await _clientFor(payload.origin).submitJoinRequest(request)) {
      case Ok(:final value):
        final pending = PendingJoin(
          origin: payload.origin,
          joinRequestId: value.joinRequestId,
          statusToken: value.statusToken,
          expiresAt: value.expiresAt,
          name: normalized,
        );
        await _savePendingJoin(pending);
        _forgetName();
        return Ok(pending);
      case Err(:final error):
        return Err(ApiCallFailed(error));
    }
  }
}
