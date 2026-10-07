import 'package:drift/drift.dart';
import 'package:web_server/src/auth_db/devices_table.dart';
import 'package:web_server/src/auth_db/users_table.dart';

/// A QR-belépési kérések (ADR 0051 D4, Addendum 3 K5).
///
/// A kihívás nyíltan áll, mert a jóváhagyás ellenőrzése az aláírt üzenetet
/// ebből rakja össze; 60 mp-ig él, és a QR-ban amúgy is nyilvános. A
/// kötő-tokennek csak a hash-e van itt. A böngésző IP-je, böngészője és
/// OS-e a kérés nyitásakor rögzül; a jóváhagyó fiók, eszköz és IP a
/// jóváhagyáskor. A beváltott kérés sora törlődik.
///
/// Row-class: `LoginRequestRow`.
@DataClassName('LoginRequestRow')
class LoginRequests extends Table {
  TextColumn get id => text()();
  TextColumn get challenge => text()();
  BlobColumn get bindingDigest => blob()();
  TextColumn get state => text()();
  TextColumn get ip => text()();
  TextColumn get browser => text().nullable()();
  TextColumn get os => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get expiresAtMs => integer()();
  TextColumn get userId => text().nullable().references(
    Users,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get deviceId => text().nullable().references(
    Devices,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get phoneIp => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (state IN ('pending', 'opened', 'approved'))",
  ];
}
