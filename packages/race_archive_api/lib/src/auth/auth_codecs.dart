import 'dart:convert';
import 'dart:typed_data';

import 'package:race_archive_api/src/auth/account_info.dart';
import 'package:race_archive_api/src/auth/base64url.dart';
import 'package:race_archive_api/src/auth/browser_login_details.dart';
import 'package:race_archive_api/src/auth/display_name.dart';
import 'package:race_archive_api/src/auth/enrollment_request.dart';
import 'package:race_archive_api/src/auth/enrollment_result.dart';
import 'package:race_archive_api/src/auth/issued_secret.dart';
import 'package:race_archive_api/src/auth/login_request_status.dart';
import 'package:race_archive_api/src/auth/login_request_ticket.dart';
import 'package:race_archive_api/src/auth/qr_payload.dart';
import 'package:race_archive_api/src/auth/signed_device_request.dart';
import 'package:race_archive_api/src/auth/user_role.dart';
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
    runDecode(() => _readAccountInfo(JsonReader.root(json)));

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
    requestId: _secret(reader, 'requestId', loginRequestIdLength),
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
    account: accountReader == null ? null : _readAccountInfo(accountReader),
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
    token: _secret(reader, 'token', secretTokenLength),
    publicKey: _bytes(reader, 'publicKey'),
    deviceKey: _bytes(reader, 'deviceKey'),
    deviceName: _displayName(reader, 'deviceName'),
    model: _displayName(reader, 'model'),
    signature: _bytes(reader, 'signature'),
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
        account: _readAccountInfo(reader.object('account')),
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
        value: _secret(reader, 'value', secretTokenLength),
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
        ? _secret(reader, 'challenge', secretTokenLength)
        : null,
    signature: _bytes(reader, 'signature'),
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
      () => _secret(JsonReader.root(json), 'challenge', secretTokenLength),
    );

AccountInfo _readAccountInfo(JsonReader reader) => AccountInfo(
  userId: reader.nonEmptyString('userId'),
  name: reader.nonEmptyString('name'),
  role: reader.enumByName('role', UserRole.values),
);

String _readCode(Object? item, String path) {
  if (item is String && item.isNotEmpty) return item;
  JsonReader.failAt(path, 'non-empty string');
}

// Egy base64url titok a megadott bájthosszal; minden más hiba még a
// DB-keresés előtt.
String _secret(JsonReader reader, String key, int length) {
  final value = reader.string(key);
  if (decodeBase64UrlUnpadded(value)?.length == length) return value;
  JsonReader.failAt(reader.childPath(key), 'base64url of $length bytes');
}

// Szabványos base64, csak a kanonikus alak: egy aláírásnak és egy
// kulcsnak így egy szöveges alakja van.
Uint8List _bytes(JsonReader reader, String key) {
  final value = reader.nonEmptyString(key);
  try {
    final bytes = base64.decode(value);
    if (base64.encode(bytes) == value) return bytes;
  } on FormatException {
    // Lent hibaként jelezzük.
  }
  JsonReader.failAt(reader.childPath(key), 'canonical base64');
}

String _displayName(JsonReader reader, String key) =>
    normalizeDisplayName(reader.string(key)) ??
    JsonReader.failAt(reader.childPath(key), 'display name');
