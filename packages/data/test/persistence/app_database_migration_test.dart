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
    // ARRANGE — v1 DB szimulációja: friss v2 DB egy fájlon, majd a Settings
    // táblát eldobjuk és user_version=1-re állítunk. A v1→v2 különbség CSAK a
    // Settings tábla, így ez hűen egy valódi v1 device-DB-t ad (drift-generált
    // sémával, kézi CREATE nélkül).
    final v2 = AppDatabase(NativeDatabase(dbFile));
    await v2.customStatement('DROP TABLE settings');
    await v2.customStatement('PRAGMA user_version = 1');
    await v2.close();

    // ACT — újranyitás: user_version (1) < schemaVersion (2) → onUpgrade.
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
}
