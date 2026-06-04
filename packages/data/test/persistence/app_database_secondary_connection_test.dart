import 'dart:io';

import 'package:data/src/persistence/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('foretack_secondary_test');
    dbFile = File('${tempDir.path}/foretack.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('a beforeOpen WAL-módba kapcsolja a fájl-alapú kapcsolatot', () async {
    // ARRANGE — fájl-alapú kapcsolat (WAL csak lemezes DB-n értelmezett).
    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // ACT
    final row = await db.customSelect('PRAGMA journal_mode').getSingle();

    // ASSERT — a journal_mode WAL (mindkét ctor a közös beforeOpen-t futtatja).
    expect(row.data.values.first, equals('wal'));
  });

  test('a secondary egy már migrált sémán migráció nélkül nyílik', () async {
    // ARRANGE — az elsődleges (UI) kapcsolat migrálja a sémát v2-re.
    final ui = AppDatabase(NativeDatabase(dbFile));
    await ui.select(ui.races).get(); // kierőlteti a megnyitást + migrációt
    await ui.close();

    // ACT — a másodlagos engine-kapcsolat ugyanarra a fájlra.
    final secondary = AppDatabase.secondary(NativeDatabase(dbFile));
    addTearDown(secondary.close);

    // ASSERT — nem dob, és a kész sémán olvasható a telemetria-tábla.
    expect(await secondary.select(secondary.telemetryRecords).get(), isEmpty);
  });

  test('a secondary friss sémán dob, nem migrál csendben', () async {
    // ARRANGE — friss fájl, nincs előzetes UI-migráció.
    final secondary = AppDatabase.secondary(NativeDatabase(dbFile));
    addTearDown(secondary.close);

    // ACT + ASSERT — az első query kierőlteti a megnyitást → az onCreate dob
    // (a néma konkurens migráció helyett, ADR 0017 D6).
    await expectLater(
      secondary.select(secondary.telemetryRecords).get(),
      throwsA(predicate<Object>((e) => e.toString().contains('másodlagos'))),
    );
  });
}
