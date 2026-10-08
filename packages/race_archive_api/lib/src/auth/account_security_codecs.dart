import 'package:race_archive_api/src/auth/access_management_codecs.dart';
import 'package:race_archive_api/src/auth/account_security.dart';
import 'package:race_archive_api/src/auth/auth_json_fields.dart';
import 'package:race_archive_api/src/auth/fallback_login.dart';
import 'package:race_archive_api/src/auth/issued_recovery_codes.dart';
import 'package:race_archive_api/src/auth/login_banner.dart';
import 'package:race_archive_api/src/auth/login_method.dart';
import 'package:race_archive_api/src/auth/password_change.dart';
import 'package:race_archive_api/src/auth/suspicious_login.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:shared/shared.dart';

// A tartalék belépés, a jelszó, a kódok és a szalag kodekjei (ADR 0051
// Addendum 6 N10). A jelszót és a kódot nem egységesítjük: ahogy a
// felhasználó beírta, úgy megy át (J4).

/// [FallbackLogin] → JSON (`POST /api/auth/fallback-login`).
Map<String, Object?> encodeFallbackLogin(FallbackLogin login) =>
    <String, Object?>{'secret': login.secret};

/// JSON → [FallbackLogin]; a hosszát a szerver nézi, egyforma hibával.
Result<FallbackLogin, DecodeError> decodeFallbackLogin(Object? json) =>
    runDecode(() => FallbackLogin(JsonReader.root(json).string('secret')));

/// [PasswordChange] → JSON (`POST /api/auth/account/password`).
Map<String, Object?> encodePasswordChange(PasswordChange change) =>
    <String, Object?>{
      'password': change.password,
      ...encodeSignedAction(change.action),
    };

/// JSON → [PasswordChange]; a jelszó szabályát a szerver nézi.
Result<PasswordChange, DecodeError> decodePasswordChange(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return PasswordChange(
        password: reader.string('password'),
        action: readSignedAction(reader),
      );
    });

/// [IssuedRecoveryCodes] → JSON.
Map<String, Object?> encodeIssuedRecoveryCodes(IssuedRecoveryCodes codes) =>
    <String, Object?>{'recoveryCodes': codes.codes};

/// JSON → [IssuedRecoveryCodes].
Result<IssuedRecoveryCodes, DecodeError> decodeIssuedRecoveryCodes(
  Object? json,
) => runDecode(
  () => IssuedRecoveryCodes(
    JsonReader.root(json).list('recoveryCodes', _readCode),
  ),
);

/// [AccountSecurity] → JSON (`GET /api/auth/account/security`).
Map<String, Object?> encodeAccountSecurity(AccountSecurity security) =>
    <String, Object?>{
      'passwordSetAt': security.passwordSetAt?.millisecondsSinceEpoch,
      'recoveryCodesLeft': security.recoveryCodesLeft,
      'recoveryCodesGeneratedAt':
          security.recoveryCodesGeneratedAt?.millisecondsSinceEpoch,
    };

/// JSON → [AccountSecurity]; a hiányzó `recoveryCodesGeneratedAt` (egy
/// régebbi szerver) `null` (Addendum 10 Z12).
Result<AccountSecurity, DecodeError> decodeAccountSecurity(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return AccountSecurity(
        passwordSetAt: reader.optionalUtcMillis('passwordSetAt'),
        recoveryCodesLeft: reader.integerAtLeast('recoveryCodesLeft', 0),
        recoveryCodesGeneratedAt: reader.optionalUtcMillis(
          'recoveryCodesGeneratedAt',
        ),
      );
    });

/// [LoginBanner] → JSON (`GET /api/auth/banner`).
Map<String, Object?> encodeLoginBanner(LoginBanner banner) => <String, Object?>{
  'suspicious': [
    for (final login in banner.suspicious) _suspiciousJson(login),
  ],
  'pendingJoinRequests': banner.pendingJoinRequests,
};

/// JSON → [LoginBanner].
Result<LoginBanner, DecodeError> decodeLoginBanner(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return LoginBanner(
        suspicious: reader.list(
          'suspicious',
          (item, path) => _readSuspicious(JsonReader.at(item, path)),
        ),
        pendingJoinRequests: reader.integerAtLeast('pendingJoinRequests', 0),
      );
    });

Map<String, Object?> _suspiciousJson(SuspiciousLogin login) =>
    <String, Object?>{
      'id': login.id,
      'userId': login.userId,
      'userName': login.userName,
      'method': login.method.name,
      'ip': login.ip,
      'browser': login.browser,
      'os': login.os,
      'country': login.country,
      'city': login.city,
      'createdAt': login.createdAt.millisecondsSinceEpoch,
      'sessionId': login.sessionId,
    };

SuspiciousLogin _readSuspicious(JsonReader reader) => SuspiciousLogin(
  id: reader.nonEmptyString('id'),
  userId: reader.nonEmptyString('userId'),
  userName: reader.nonEmptyString('userName'),
  method: reader.enumByName('method', LoginMethod.values),
  ip: reader.nonEmptyString('ip'),
  browser: reader.optionalString('browser'),
  os: reader.optionalString('os'),
  country: reader.optionalString('country'),
  city: reader.optionalString('city'),
  createdAt: reader.utcMillis('createdAt'),
  sessionId: reader.optionalString('sessionId'),
);

String _readCode(Object? item, String path) {
  if (item is String && item.isNotEmpty) return item;
  JsonReader.failAt(path, 'non-empty string');
}
