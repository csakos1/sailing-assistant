import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_account_codec.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A fiók-fájl kulcsa, amely alatt a függő kérelem áll (ADR 0051
/// Addendum 9 X4).
const String pendingJoinKey = 'pendingJoin';

/// [pending] → a fiók-fájl JSON-objektuma, fiók nélkül (X4).
Map<String, Object?> encodePendingJoinFile(PendingJoin pending) =>
    <String, Object?>{
      'version': webAccountFileVersion,
      pendingJoinKey: <String, Object?>{
        'origin': pending.origin,
        'joinRequestId': pending.joinRequestId,
        'statusToken': pending.statusToken,
        'expiresAt': pending.expiresAt.millisecondsSinceEpoch,
        'name': pending.name,
      },
    };

/// A fiók-fájl JSON-ja → [PendingJoin], vagy `null`, ha a fájl nem egy
/// függő kérelmet hord.
///
/// A fiók és a függő kérelem kizárja egymást (X4): ha a fájlban fiók-mező
/// (`userId`) is van, a tartalom olvashatatlan, és `null`.
PendingJoin? decodePendingJoinFile(Object? json) {
  if (json is! Map<String, Object?>) return null;
  if (json['version'] != webAccountFileVersion) return null;
  if (json.containsKey('userId')) return null;
  final pending = json[pendingJoinKey];
  if (pending is! Map<String, Object?>) return null;
  final origin = _text(pending['origin']);
  final joinRequestId = _text(pending['joinRequestId']);
  final statusToken = _text(pending['statusToken']);
  final expiresAtMs = pending['expiresAt'];
  final name = _text(pending['name']);
  if (origin == null || canonicalWebOrigin(origin) != origin) return null;
  if (joinRequestId == null || statusToken == null || name == null) {
    return null;
  }
  if (expiresAtMs is! int) return null;
  return PendingJoin(
    origin: origin,
    joinRequestId: joinRequestId,
    statusToken: statusToken,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true),
    name: name,
  );
}

String? _text(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
