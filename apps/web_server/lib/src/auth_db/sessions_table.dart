import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// A webes munkamenetek (ADR 0051 D5, D7).
///
/// A token SHA-256 hash-e egyedi; az `id` a „Webes belépések" képernyő
/// kiléptetéséhez kell (A2b). A belépés módja a `LoginMethod` neve. A
/// QR-belépésnél a jóváhagyó eszköz is rögzül; az ország és a város a
/// GeoIP-ből jön (A2b), addig `null`.
///
/// Row-class: `SessionRow`.
@DataClassName('SessionRow')
class Sessions extends Table {
  TextColumn get id => text()();
  BlobColumn get tokenDigest => blob().unique()();
  TextColumn get userId =>
      text().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get deviceId => text().nullable().references(
    Devices,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get method => text()();
  TextColumn get ip => text()();
  TextColumn get browser => text().nullable()();
  TextColumn get os => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get city => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get lastSeenAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (method IN ('qr', 'password', 'recoveryCode'))",
  ];
}
