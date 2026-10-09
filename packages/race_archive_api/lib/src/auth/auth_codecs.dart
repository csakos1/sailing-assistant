import 'dart:convert';

import 'package:race_archive_api/src/auth/account_info.dart';
import 'package:race_archive_api/src/auth/auth_json_fields.dart';
import 'package:race_archive_api/src/auth/browser_login_details.dart';
import 'package:race_archive_api/src/auth/enrollment_request.dart';
import 'package:race_archive_api/src/auth/enrollment_result.dart';
import 'package:race_archive_api/src/auth/issued_secret.dart';
import 'package:race_archive_api/src/auth/login_request_status.dart';
import 'package:race_archive_api/src/auth/login_request_ticket.dart';
import 'package:race_archive_api/src/auth/qr_payload.dart';
import 'package:race_archive_api/src/auth/signed_device_request.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

// A hitelesítés kodekjei (ADR 0051 Addendum 3 K6, Addendum 4 L2). A
// bájtok (kulcs, aláírás) szabványos base64-ben, ahogy a
// `biometric_signature` adja; az időpontok UTC epoch ms-ben. A titkok
// (token, kihívás) base64url-ek, és a dekóder a hosszukat is nézi.

/// [AccountInfo] → JSON (`GET /api/auth/me`).
Map<String, Object?> encodeAccountInfo(AccountInfo account) =>
    <String, Object?>{
      'userId': account.userId,
      'name': account.name,
      'role': account.role.name,
    };

/// JSON → [AccountInfo].
Result<AccountInfo, DecodeError> decodeAccountInfo(Object? json) =>
    runDecode(() => readAccountInfo(JsonReader.root(json)));

/// [LoginRequestTicket] → JSON (`POST /api/auth/login-requests`).
Map<String, Object?> encodeLoginRequestTicket(LoginRequestTicket ticket) =>
    <String, Object?>{
      'requestId': ticket.requestId,
      'qrText': ticket.qrText,
      'expiresAt': ticket.expiresAt.millisecondsSinceEpoch,
    };

/// JSON → [LoginRequestTicket].
Result<LoginRequestTicket, DecodeError> decodeLoginRequestTicket(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  return LoginRequestTicket(
    requestId: readSecret(reader, 'requestId', loginRequestIdLength),
    qrText: reader.nonEmptyString('qrText'),
    expiresAt: reader.utcMillis('expiresAt'),
  );
});

/// [LoginRequestStatus] → JSON (`POST …/poll`).
Map<String, Object?> encodeLoginRequestStatus(LoginRequestStatus status) =>
    <String, Object?>{
      'state': status.state.name,
      'account': switch (status.account) {
        null => null,
        final AccountInfo account => encodeAccountInfo(account),
      },
    };

/// JSON → [LoginRequestStatus].
///
/// A fiók pontosan a `signedIn` állapotnál van jelen.
Result<LoginRequestStatus, DecodeError> decodeLoginRequestStatus(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  final state = reader.enumByName('state', LoginRequestState.values);
  final accountReader = reader.optionalObject('account');
  final isSignedIn = state == LoginRequestState.signedIn;
  if (isSignedIn != (accountReader != null)) {
    JsonReader.failAt(
      reader.childPath('account'),
      'account exactly when signedIn',
    );
  }
  return LoginRequestStatus(
    state: state,
    account: accountReader == null ? null : readAccountInfo(accountReader),
  );
});

/// [BrowserLoginDetails] → JSON (`POST …/open`).
Map<String, Object?> encodeBrowserLoginDetails(BrowserLoginDetails details) =>
    <String, Object?>{
      'ip': details.ip,
      'browser': details.browser,
      'os': details.os,
      'country': details.country,
      'city': details.city,
    };

/// JSON → [BrowserLoginDetails].
Result<BrowserLoginDetails, DecodeError> decodeBrowserLoginDetails(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  return BrowserLoginDetails(
    ip: reader.nonEmptyString('ip'),
    browser: reader.optionalString('browser'),
    os: reader.optionalString('os'),
    country: reader.optionalString('country'),
    city: reader.optionalString('city'),
  );
});

/// [EnrollmentRequest] → JSON (`POST /api/auth/enrollments`).
Map<String, Object?> encodeEnrollmentRequest(EnrollmentRequest request) =>
    <String, Object?>{
      'token': request.token,
      'publicKey': base64Encode(request.publicKey),
      'deviceKey': base64Encode(request.deviceKey),
      'deviceName': request.deviceName,
      'model': request.model,
      'signature': base64Encode(request.signature),
    };

/// JSON → [EnrollmentRequest].
///
/// A token 256 bites base64url, az eszköz neve és típusa a
/// `normalizeDisplayName` szerint egységesítve. A kulcsok alakját a
/// szerver ellenőrzi.
Result<EnrollmentRequest, DecodeError> decodeEnrollmentRequest(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  return EnrollmentRequest(
    token: readSecret(reader, 'token', secretTokenLength),
    publicKey: readBytes(reader, 'publicKey'),
    deviceKey: readBytes(reader, 'deviceKey'),
    deviceName: readDisplayName(reader, 'deviceName'),
    model: readDisplayName(reader, 'model'),
    signature: readBytes(reader, 'signature'),
  );
});

/// [EnrollmentResult] → JSON.
Map<String, Object?> encodeEnrollmentResult(EnrollmentResult result) =>
    <String, Object?>{
      'account': encodeAccountInfo(result.account),
      'deviceId': result.deviceId,
      'recoveryCodes': result.recoveryCodes,
    };

/// JSON → [EnrollmentResult].
Result<EnrollmentResult, DecodeError> decodeEnrollmentResult(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return EnrollmentResult(
        account: readAccountInfo(reader.object('account')),
        deviceId: reader.nonEmptyString('deviceId'),
        recoveryCodes: reader.list('recoveryCodes', _readCode),
      );
    });

/// [IssuedSecret] → JSON (kihívás vagy eszköz-token).
Map<String, Object?> encodeIssuedSecret(IssuedSecret secret) =>
    <String, Object?>{
      'value': secret.value,
      'expiresAt': secret.expiresAt.millisecondsSinceEpoch,
    };

/// JSON → [IssuedSecret]; az érték 256 bites base64url.
Result<IssuedSecret, DecodeError> decodeIssuedSecret(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return IssuedSecret(
        value: readSecret(reader, 'value', secretTokenLength),
        expiresAt: reader.utcMillis('expiresAt'),
      );
    });

/// [SignedDeviceRequest] → JSON (`/device-tokens`, `…/approval`).
Map<String, Object?> encodeSignedDeviceRequest(SignedDeviceRequest request) =>
    <String, Object?>{
      'deviceId': request.deviceId,
      'challenge': request.challenge,
      'signature': base64Encode(request.signature),
    };

/// JSON → [SignedDeviceRequest]; a kihívás, ha van, 256 bites base64url.
Result<SignedDeviceRequest, DecodeError> decodeSignedDeviceRequest(
  Object? json,
) => runDecode(() {
  final reader = JsonReader.root(json);
  final hasChallenge = reader.optionalString('challenge') != null;
  return SignedDeviceRequest(
    deviceId: reader.nonEmptyString('deviceId'),
    challenge: hasChallenge
        ? readSecret(reader, 'challenge', secretTokenLength)
        : null,
    signature: readBytes(reader, 'signature'),
  );
});

/// A kihívás kérése (`POST /api/auth/device-challenges`): `{deviceId}`.
Map<String, Object?> encodeDeviceChallengeRequest(String deviceId) =>
    <String, Object?>{'deviceId': deviceId};

/// JSON → az eszköz azonosítója.
Result<String, DecodeError> decodeDeviceChallengeRequest(Object? json) =>
    runDecode(() => JsonReader.root(json).nonEmptyString('deviceId'));

/// A belépési kérés megnyitása (`POST …/open`): `{challenge}`, a QR
/// kihívása. Ezzel bizonyítja a telefon, hogy a QR-t látta.
Map<String, Object?> encodeLoginRequestOpening(String challenge) =>
    <String, Object?>{'challenge': challenge};

/// JSON → a QR kihívása.
Result<String, DecodeError> decodeLoginRequestOpening(Object? json) =>
    runDecode(
      () => readSecret(JsonReader.root(json), 'challenge', secretTokenLength),
    );

String _readCode(Object? item, String path) {
  if (item is String && item.isNotEmpty) return item;
  JsonReader.failAt(path, 'non-empty string');
}
