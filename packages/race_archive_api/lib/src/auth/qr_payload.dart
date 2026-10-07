import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/auth/base64url.dart';
import 'package:race_archive_api/src/auth/web_origin.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

/// A belépési kérés azonosítójának hossza bájtban (128 bit, ADR 0051 D4).
const int loginRequestIdLength = 16;

/// A belépési kihívás és a regisztrációs token hossza bájtban (256 bit).
const int secretTokenLength = 32;

const String _loginPrefix = 'foretack-login:v1:';
const String _enrollPrefix = 'foretack-enroll:v1:';
final RegExp _foretackPrefix = RegExp('^foretack-[a-z]+:v[0-9]+:');

/// Egy beolvasott Foretack QR-kód tartalma (ADR 0051 D3, D4).
///
/// Sealed: az app kimerítő `switch`-csel dönti el, belépés vagy
/// regisztráció következik.
sealed class QrPayload extends Equatable {
  const QrPayload({required this.origin});

  /// A szerver kanonikus origója (`canonicalWebOrigin`).
  final String origin;
}

/// A weboldal belépési QR-ja: `foretack-login:v1:` + base64url(JSON).
final class LoginQrPayload extends QrPayload {
  /// Belépési kérés a [requestId] azonosítóval és a [challenge] kihívással.
  const LoginQrPayload({
    required super.origin,
    required this.requestId,
    required this.challenge,
  });

  /// A kérés azonosítója, base64url (128 bit).
  final String requestId;

  /// Az egyszer használatos kihívás, base64url (256 bit).
  final String challenge;

  @override
  List<Object?> get props => [origin, requestId, challenge];

  // A kihívás ne kerüljön naplóba vagy tesztkimenetbe.
  @override
  String toString() => 'LoginQrPayload($origin, $requestId, …)';
}

/// A `create_owner_enrollment` CLI QR-ja: `foretack-enroll:v1:` +
/// base64url(JSON).
final class EnrollQrPayload extends QrPayload {
  /// Regisztráció a [token] egyszer használatos tokennel.
  const EnrollQrPayload({required super.origin, required this.token});

  /// A regisztrációs token, base64url (256 bit).
  final String token;

  @override
  List<Object?> get props => [origin, token];

  // A token ne kerüljön naplóba vagy tesztkimenetbe.
  @override
  String toString() => 'EnrollQrPayload($origin, …)';
}

/// Miért nem használható egy beolvasott QR-kód.
enum QrPayloadError {
  /// Nem Foretack-kód (pl. egy weboldal címe).
  notForetack,

  /// Foretack-kód, de ismeretlen fajta vagy verzió (újabb app kellene).
  unsupportedVersion,

  /// Foretack-kód, de a tartalma hibás.
  malformed,
}

/// A [payload] QR-szövege.
String encodeQrPayload(QrPayload payload) => switch (payload) {
  LoginQrPayload(:final origin, :final requestId, :final challenge) =>
    _loginPrefix +
        _encodeJson({
          'origin': origin,
          'requestId': requestId,
          'challenge': challenge,
        }),
  EnrollQrPayload(:final origin, :final token) =>
    _enrollPrefix + _encodeJson({'origin': origin, 'token': token}),
};

/// A beolvasott [text] mint Foretack QR-tartalom.
///
/// Minden mezőt ellenőriz: az origó kanonikus, az azonosító és a titkok
/// kanonikus base64url-ek a megadott hosszal. Az app így egy hibás vagy
/// hamisított kódot még a hálózat előtt elutasít.
Result<QrPayload, QrPayloadError> decodeQrPayload(String text) {
  if (text.startsWith(_loginPrefix)) {
    return _decodeBody(text.substring(_loginPrefix.length), _readLogin);
  }
  if (text.startsWith(_enrollPrefix)) {
    return _decodeBody(text.substring(_enrollPrefix.length), _readEnroll);
  }
  if (_foretackPrefix.hasMatch(text)) {
    return const Err(QrPayloadError.unsupportedVersion);
  }
  return const Err(QrPayloadError.notForetack);
}

String _encodeJson(Map<String, String> fields) =>
    encodeBase64UrlUnpadded(utf8.encode(jsonEncode(fields)));

Result<QrPayload, QrPayloadError> _decodeBody(
  String body,
  QrPayload? Function(JsonReader reader) read,
) {
  final bytes = decodeBase64UrlUnpadded(body);
  if (bytes == null) return const Err(QrPayloadError.malformed);
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return const Err(QrPayloadError.malformed);
  }
  final result = runDecode(() => read(JsonReader.root(json)));
  if (result case Ok(value: final QrPayload payload)) return Ok(payload);
  return const Err(QrPayloadError.malformed);
}

LoginQrPayload? _readLogin(JsonReader reader) {
  final origin = canonicalWebOrigin(reader.string('origin'));
  final requestId = reader.string('requestId');
  final challenge = reader.string('challenge');
  final isValid =
      origin != null &&
      _hasLength(requestId, loginRequestIdLength) &&
      _hasLength(challenge, secretTokenLength);
  if (!isValid) return null;
  return LoginQrPayload(
    origin: origin,
    requestId: requestId,
    challenge: challenge,
  );
}

EnrollQrPayload? _readEnroll(JsonReader reader) {
  final origin = canonicalWebOrigin(reader.string('origin'));
  final token = reader.string('token');
  if (origin == null || !_hasLength(token, secretTokenLength)) return null;
  return EnrollQrPayload(origin: origin, token: token);
}

bool _hasLength(String value, int length) =>
    decodeBase64UrlUnpadded(value)?.length == length;
