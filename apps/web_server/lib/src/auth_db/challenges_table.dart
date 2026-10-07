import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';

/// Az eszköz-token kihívásai (ADR 0051 Addendum 3 K2, K3).
///
/// Csak a kihívás SHA-256 hash-e tárolódik. Egyszer használatos, 60 mp-ig
/// él, és csak annak az eszköznek szól, amelyik kérte.
///
/// Row-class: `ChallengeRow`.
@DataClassName('ChallengeRow')
class Challenges extends Table {
  BlobColumn get digest => blob()();
  TextColumn get deviceId =>
      text().references(Devices, #id, onDelete: KeyAction.cascade)();
  IntColumn get expiresAtMs => integer()();

  @override
  Set<Column> get primaryKey => {digest};
}
