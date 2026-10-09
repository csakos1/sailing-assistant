import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// Az `owner` helyreállító kódjai (ADR 0051 D6, Addendum 2 J6).
///
/// Csak a kód HMAC-SHA-256-ja tárolódik (`AuthSecret.digestRecoveryCode`):
/// egy kiszivárgott DB-ből a titok nélkül nem próbálgathatók. A felhasznált
/// kód sora megmarad (`used_at_ms`).
///
/// Row-class: `RecoveryCodeRow`.
@DataClassName('RecoveryCodeRow')
class RecoveryCodes extends Table {
  BlobColumn get codeDigest => blob()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get createdAtMs => integer()();
  IntColumn get usedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {codeDigest};
}
