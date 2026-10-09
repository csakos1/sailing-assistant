import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';

/// A szerver kihívásai (ADR 0051 Addendum 3 K2, K3, Addendum 5 M2).
///
/// Csak a kihívás SHA-256 hash-e tárolódik. Egyszer használatos, 60 mp-ig
/// él, csak annak az eszköznek szól, amelyik kérte, és csak a `purpose`
/// céljára (eszköz-token vagy ujjlenyomatos művelet).
///
/// Row-class: `ChallengeRow`.
@DataClassName('ChallengeRow')
class Challenges extends Table {
  BlobColumn get digest => blob()();
  TextColumn get deviceId =>
      text().references(Devices, #id, onDelete: KeyAction.cascade)();
  TextColumn get purpose => text()();
  IntColumn get expiresAtMs => integer()();

  @override
  Set<Column> get primaryKey => {digest};

  @override
  List<String> get customConstraints => [
    "CHECK (purpose IN ('deviceToken', 'action'))",
  ];
}
