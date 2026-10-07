import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/device_identity.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Egy szerver kliense az origója szerint.
typedef WebAccessClientFor = WebAccessApiClient Function(String origin);

/// Egy sikeres regisztráció: az új fiók, a 10 helyreállító kód (csak
/// most látszanak, 18g) és a telefon neve (18f).
@immutable
class CompletedEnrollment {
  /// Regisztráció az [account] fiókkal, a [recoveryCodes] kódokkal, a
  /// [deviceName] telefonként.
  const CompletedEnrollment({
    required this.account,
    required this.recoveryCodes,
    required this.deviceName,
  });

  /// A mentett új fiók.
  final WebAccount account;

  /// A szerver által most kiadott helyreállító kódok.
  final List<String> recoveryCodes;

  /// A telefon neve, ahogy a szerver ismeri.
  final String deviceName;
}

/// A tulajdonos telefonjának regisztrációja (ADR 0051 D3, Addendum 8 V1,
/// V4, V8).
///
/// Előbb a régi helyi fiók és a két kulcs törlődik (a fiók-csere és egy
/// félbemaradt próbálkozás miatt is), utána két új kulcs, ujjlenyomatos
/// aláírás és a szerverhívás jön. A fiók csak a sikeres válasz után kerül
/// a tárba.
class EnrollmentFlow {
  /// Folyamat a [_clientFor] kliensekkel, a [_keys] kulcsműveletekkel, a
  /// [_readIdentity] telefonadatokkal; a fiókot a [_saveAccount] menti, a
  /// régit a [_clearAccount] törli.
  EnrollmentFlow({
    required WebAccessClientFor clientFor,
    required WebKeyOperations keys,
    required ReadDeviceIdentity readIdentity,
    required Future<void> Function(WebAccount account) saveAccount,
    required Future<void> Function() clearAccount,
  }) : _clientFor = clientFor,
       _keys = keys,
       _readIdentity = readIdentity,
       _saveAccount = saveAccount,
       _clearAccount = clearAccount;

  final WebAccessClientFor _clientFor;
  final WebKeyOperations _keys;
  final ReadDeviceIdentity _readIdentity;
  final Future<void> Function(WebAccount account) _saveAccount;
  final Future<void> Function() _clearAccount;

  /// Regisztráció a [payload] tokenjével; a [prompt] az ujjlenyomat-ablak
  /// szövege (H6).
  Future<Result<CompletedEnrollment, WebAccessError>> run(
    EnrollQrPayload payload, {
    required BiometricPromptText prompt,
  }) async {
    await _clearAccount();
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
    final message = enrollmentMessage(
      origin: payload.origin,
      token: payload.token,
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
    final request = EnrollmentRequest(
      token: payload.token,
      publicKey: publicKey,
      deviceKey: deviceKey,
      deviceName: identity.deviceName,
      model: identity.model,
      signature: signature,
    );
    switch (await _clientFor(payload.origin).enroll(request)) {
      case Ok(:final value):
        final account = WebAccount(
          origin: payload.origin,
          account: value.account,
          deviceId: value.deviceId,
        );
        await _saveAccount(account);
        return Ok(
          CompletedEnrollment(
            account: account,
            recoveryCodes: value.recoveryCodes,
            deviceName: identity.deviceName,
          ),
        );
      case Err(:final error):
        return Err(ApiCallFailed(error));
    }
  }
}
