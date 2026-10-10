import 'dart:io';

import 'package:data/src/persistence/app_database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

// A v6 (ADR 0055 D3) négy oszlopa a races táblán. Egy v6-nál régebbi DB
// szimulációjához ezeket is el kell dobni, különben a v6 addColumn-ja egy
// már meglévő oszlopra futna.
const _v6RaceColumns = [
  'scheduled_start_at',
  'start_point_name',
  'start_point_latitude',
  'start_point_longitude',
];

Future<void> _dropV6RaceColumns(AppDatabase database) async {
  for (final column in _v6RaceColumns) {
    await database.customStatement('ALTER TABLE races DROP COLUMN $column');
  }
}

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('foretack_migration_test');
    dbFile = File('${tempDir.path}/foretack.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('v1 → v2: az onUpgrade létrehozza a Settings táblát', () async {
    // ARRANGE — v1 DB szimulációja: a v1 séma SEM a Settings, SEM a
    // SnapshotLogs táblát nem tartalmazta (utóbbi a v3). Friss DB-t nyitunk,
    // mindkét táblát eldobjuk, és user_version=1-re állítunk — így hűen egy
    // valódi v1 device-DB-t kapunk (drift-generált sémával, kézi CREATE nélkül).
    final fresh = AppDatabase(NativeDatabase(dbFile));
    await fresh.customStatement('DROP TABLE settings');
    await fresh.customStatement('DROP TABLE snapshot_logs');
    await _dropV6RaceColumns(fresh);
    await fresh.customStatement('PRAGMA user_version = 1');
    await fresh.close();

    // ACT — újranyitás: user_version (1) < schemaVersion → onUpgrade (1-től).
    final migrated = AppDatabase(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // ASSERT — a Settings tábla létrejött és round-trip-el; a meglévő táblák
    // (races) érintetlenül megmaradtak.
    await migrated
        .into(migrated.settings)
        .insert(SettingsCompanion.insert(key: 'k', value: 'v'));
    final settingsRows = await migrated.select(migrated.settings).get();
    expect(settingsRows, hasLength(1));
    expect(settingsRows.single.value, equals('v'));
    expect(await migrated.select(migrated.races).get(), isEmpty);
  });

  test('v2 → v3: az onUpgrade létrehozza a SnapshotLogs táblát', () async {
    // ARRANGE — v2 DB szimulációja: friss DB egy fájlon, majd CSAK a
    // snapshot_logs táblát eldobjuk és user_version=2-re állítunk. A v2→v3
    // különbség kizárólag a SnapshotLogs tábla.
    final fresh = AppDatabase(NativeDatabase(dbFile));
    await fresh.customStatement('DROP TABLE snapshot_logs');
    await _dropV6RaceColumns(fresh);
    await fresh.customStatement('PRAGMA user_version = 2');
    await fresh.close();

    // ACT — újranyitás: user_version (2) < schemaVersion → onUpgrade.
    final migrated = AppDatabase(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // ASSERT — a SnapshotLogs tábla létrejött (üres select nem dob), a
    // meglévő táblák (races) érintetlenek.
    expect(await migrated.select(migrated.snapshotLogs).get(), isEmpty);
    expect(await migrated.select(migrated.races).get(), isEmpty);
  });

  test('v4 → v5: az onUpgrade létrehozza a RaceTrackStats táblát', () async {
    // ARRANGE — v4 DB szimulációja: friss DB egy fájlon, majd CSAK a
    // race_track_stats táblát dobjuk el, és user_version=4-re állítunk.
    // A v4→v5 különbség kizárólag ez az egy tábla.
    final fresh = AppDatabase(NativeDatabase(dbFile));
    await fresh.customStatement('DROP TABLE race_track_stats');
    await _dropV6RaceColumns(fresh);
    await fresh.customStatement('PRAGMA user_version = 4');
    await fresh.close();

    // ACT — újranyitás: user_version (4) < schemaVersion → onUpgrade.
    final migrated = AppDatabase(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // ASSERT — a tábla létrejött (üres select nem dob), és a meglévő
    // táblák érintetlenek.
    expect(await migrated.select(migrated.raceTrackStats).get(), isEmpty);
    expect(await migrated.select(migrated.races).get(), isEmpty);
  });

  test('v5 -> v6: existing races get an empty schedule', () async {
    // ARRANGE - a v5 DB with one race written in the v5 shape.
    final fresh = AppDatabase(NativeDatabase(dbFile));
    await _dropV6RaceColumns(fresh);
    await fresh.customStatement(
      'INSERT INTO races '
      '(id, name, status_index, active_mark_index, created_at) '
      "VALUES ('race-1', 'Regi', 0, 0, 1750000000)",
    );
    await fresh.customStatement('PRAGMA user_version = 5');
    await fresh.close();

    // ACT - reopening runs onUpgrade from 5.
    final migrated = AppDatabase(NativeDatabase(dbFile));
    addTearDown(migrated.close);
    final rows = await migrated.select(migrated.races).get();

    // ASSERT - the race kept its data, the new columns are empty.
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Regi');
    expect(rows.single.scheduledStartAt, isNull);
    expect(rows.single.startPointName, isNull);
    expect(rows.single.startPointLatitude, isNull);
    expect(rows.single.startPointLongitude, isNull);
  });
}
