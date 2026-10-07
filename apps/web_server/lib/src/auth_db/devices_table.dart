import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// A regisztrált telefonok és a nyilvános kulcsuk (ADR 0051 D3, D10).
///
/// A kulcs a SubjectPublicKeyInfo DER (91 bájt), egyedi: egy kulcs csak
/// egy eszközé lehet. A visszavont eszköz sora megmarad (`revoked_at_ms`),
/// hogy az app pontos hibát kaphasson; a fiók törlése az eszközeit is
/// törli.
///
/// Row-class: `DeviceRow`.
@DataClassName('DeviceRow')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  BlobColumn get publicKey => blob().unique()();
  TextColumn get name => text()();
  TextColumn get model => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get lastUsedAtMs => integer().nullable()();
  IntColumn get revokedAtMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
