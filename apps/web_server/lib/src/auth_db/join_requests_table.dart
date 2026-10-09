import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// A legénység csatlakozási kérelmei (ADR 0051 D3, Addendum 5 M3, M10).
///
/// A lekérdező tokennek csak a hash-e van itt. A két kulcs a jóváhagyásig
/// csak itt él; jóváhagyáskor kerülnek a `devices` táblába. A sor 24 óráig
/// él, döntés után is, hogy a telefon a jóváhagyást egy hálózati hiba után
/// is megtudhassa. A fiók és az eszköz külső kulcsa `SET NULL`: egy
/// eltávolított tag kérelme így `notApproved` lesz.
///
/// Row-class: `JoinRequestRow`.
@DataClassName('JoinRequestRow')
class JoinRequests extends Table {
  TextColumn get id => text()();
  BlobColumn get statusDigest => blob()();
  TextColumn get name => text()();
  TextColumn get deviceName => text()();
  TextColumn get model => text()();
  BlobColumn get publicKey => blob()();
  BlobColumn get deviceKey => blob()();
  TextColumn get ip => text()();
  TextColumn get country => text().nullable()();
  TextColumn get city => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer()();
  TextColumn get state => text()();
  TextColumn get userId => text().nullable().references(
    Users,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get deviceId => text().nullable().references(
    Devices,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('pending', 'approved', 'rejected'))",
  ];
}
