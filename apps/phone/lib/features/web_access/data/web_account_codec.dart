import 'package:phone/features/web_access/data/web_account.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A fiók-fájl sémájának verziója (ADR 0051 Addendum 8 V3).
const int webAccountFileVersion = 1;

/// [account] → a fiók-fájl JSON-objektuma.
Map<String, Object?> encodeWebAccount(WebAccount account) => <String, Object?>{
  'version': webAccountFileVersion,
  'origin': account.origin,
  'userId': account.account.userId,
  'name': account.account.name,
  'role': account.account.role.name,
  'deviceId': account.deviceId,
};

/// A fiók-fájl JSON-ja → [WebAccount], vagy `null`, ha a tartalom nem
/// olvasható (V3).
///
/// Ismeretlen verzió, hiányzó vagy rossz típusú mező, nem kanonikus origó
/// vagy ismeretlen szerep mind `null`: a hívó ezt „nincs fiók"-nak veszi,
/// és a következő regisztráció vagy csatlakozás felülírja.
WebAccount? decodeWebAccount(Object? json) {
  if (json is! Map<String, Object?>) return null;
  if (json['version'] != webAccountFileVersion) return null;
  final origin = _text(json['origin']);
  final userId = _text(json['userId']);
  final name = _text(json['name']);
  final role = UserRole.values.asNameMap()[json['role']];
  final deviceId = _text(json['deviceId']);
  if (origin == null || canonicalWebOrigin(origin) != origin) return null;
  if (userId == null || name == null || role == null || deviceId == null) {
    return null;
  }
  return WebAccount(
    origin: origin,
    account: AccountInfo(userId: userId, name: name, role: role),
    deviceId: deviceId,
  );
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
