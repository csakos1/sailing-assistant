import 'dart:io';

import 'package:data/src/persistence/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await fresh.customStatement('PRAGMA user_version = 2');
    await fresh.close();

    // ACT — újranyitás: user_version (2) < schemaVersion (3) → onUpgrade.
    final migrated = AppDatabase(NativeDatabase(dbFile));
    addTearDown(migrated.close);

    // ASSERT — a SnapshotLogs tábla létrejött (üres select nem dob), a
    // meglévő táblák (races) érintetlenek.
    expect(await migrated.select(migrated.snapshotLogs).get(), isEmpty);
    expect(await migrated.select(migrated.races).get(), isEmpty);
  });
}
