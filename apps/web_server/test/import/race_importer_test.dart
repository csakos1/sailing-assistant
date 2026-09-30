import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/import/race_importer.dart';

import 'phone_database_fixture.dart';

void main() {
  late Directory tempDir;
  late Directory importTemp;
  late AppDatabase archive;
  late RaceImporter importer;

  setUpAll(() {
    // Az archivum, a telefon-DB-k es a migralt masolat kulon executoron
    // fut, a Drift tobbszoros-peldany figyelmeztetese itt alaptalan.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('foretack_import_test');
    importTemp = await Directory('${tempDir.path}/work').create();
    archive = AppDatabase(
      NativeDatabase(File('${tempDir.path}/archive.sqlite')),
    );
    importer = RaceImporter(archive: archive, tempRoot: importTemp);
  });

  tearDown(() async {
    await archive.close();
    await tempDir.delete(recursive: true);
  });

  File phoneFile(String name) => File('${tempDir.path}/$name.sqlite');

  ImportReport reportOf(Result<ImportReport, ImportRejection> result) =>
      switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };

  ImportRejection rejectionOf(Result<ImportReport, ImportRejection> result) =>
      switch (result) {
        Ok(:final value) => throw StateError('Err-t vartunk: $value'),
        Err(:final error) => error,
      };

  group('RaceImporter merges', () {
    test(
      'finished races with all child rows and skips unfinished ones',
      () async {
        // ARRANGE
        final phone = phoneFile('phone');
        await writePhoneDatabase(phone, [
          finishedFixtureRace('r1'),
          activeFixtureRace('r2'),
        ]);

        // ACT
        final report = reportOf(await importer(database: phone));

        // ASSERT
        expect(report.added.map((race) => race.id), ['r1']);
        expect(report.updated, isEmpty);
        expect(report.skipped, const [
          SkippedRace(id: 'r2', name: 'Futo r2', status: RaceStatus.active),
        ]);
        expect(report.warnings, isEmpty);
        expect(
          report.added.single.finishedAt,
          finishedFixtureRace('r1').finishedAt,
        );

        final stored = await RaceRepositoryImpl(archive).getRace('r1');
        expect(stored?.status, RaceStatus.finished);
        expect(stored?.marks.single.roundedAt, isNotNull);
        expect(await RaceRepositoryImpl(archive).getRace('r2'), isNull);
        expect(await countRows(archive, 'telemetry_records', 'r1'), 3);
        expect(await countRows(archive, 'snapshot_logs', 'r1'), 3);
        expect(await countRows(archive, 'race_track_stats', 'r1'), 1);
      },
    );

    test('a re-import as an update, replacing the child rows', () async {
      // ARRANGE: az elso lehuzas 3 mintaval, a masodik ugyanarrol a
      // versenyrol 5 mintaval, plusz egy uj verseny.
      final first = phoneFile('first');
      final second = phoneFile('second');
      await writePhoneDatabase(first, [finishedFixtureRace('r1')]);
      await writePhoneDatabase(second, [
        finishedFixtureRace('r1'),
        finishedFixtureRace('r3', offset: const Duration(days: 7)),
      ], samples: 5);
      reportOf(await importer(database: first));

      // ACT
      final report = reportOf(await importer(database: second));

      // ASSERT
      expect(report.updated.map((race) => race.id), ['r1']);
      expect(report.added.map((race) => race.id), ['r3']);
      expect(await countRows(archive, 'telemetry_records', 'r1'), 5);
      expect(await countRows(archive, 'snapshot_logs', 'r1'), 5);
      expect(await countRows(archive, 'race_track_stats', 'r1'), 1);
    });

    test('databases with colliding autoincrement ids without loss', () async {
      // ARRANGE: ket kulon telefon-DB, mindkettoben 1-tol indulnak az id-k.
      final deviceA = phoneFile('device-a');
      final deviceB = phoneFile('device-b');
      await writePhoneDatabase(deviceA, [finishedFixtureRace('a1')]);
      await writePhoneDatabase(deviceB, [finishedFixtureRace('b1')]);

      // ACT
      reportOf(await importer(database: deviceA));
      reportOf(await importer(database: deviceB));

      // ASSERT
      expect(await countRows(archive, 'telemetry_records', 'a1'), 3);
      expect(await countRows(archive, 'telemetry_records', 'b1'), 3);
    });

    test('an older schema after migrating the staged copy', () async {
      // ARRANGE: v4-es telefon-DB szimulacioja, mint a data migracios
      // tesztjeiben: a v5-os tabla eldobva, user_version = 4.
      final phone = phoneFile('phone-v4');
      final database = AppDatabase(NativeDatabase(phone));
      await seedRaces(database, [finishedFixtureRace('r1')]);
      await database.customStatement('DROP TABLE race_track_stats');
      await database.customStatement('PRAGMA user_version = 4');
      await database.close();

      // ACT
      final report = reportOf(await importer(database: phone));

      // ASSERT
      expect(report.added.map((race) => race.id), ['r1']);
      expect(await countRows(archive, 'telemetry_records', 'r1'), 3);
      // A v4-es telefonnak nincs track-stat tablaja; a sort az import
      // utani potlas irja (ADR 0047 Addendum 3 C7).
      expect(await countRows(archive, 'race_track_stats', 'r1'), 1);
    });
  });

  group('RaceImporter WAL handling', () {
    test('reads races that exist only in the uploaded WAL', () async {
      // ARRANGE: az elso verseny a lezaraskor (checkpoint) a fo fajlba
      // kerul; a masodikat egy ujranyitott kapcsolat irja, az csak a
      // WAL-ban van. A fajlokat nyitott kapcsolat mellett masoljuk, ahogy a
      // lehuzas a telefonrol. (Egy friss DB-nel a sema is a WAL-ban lehet,
      // ezert nem a friss DB-re epitunk.)
      final live = phoneFile('live');
      await writePhoneDatabase(live, [finishedFixtureRace('r1')]);
      final database = AppDatabase(NativeDatabase(live));
      await seedRaces(database, [
        finishedFixtureRace('r2', offset: const Duration(days: 1)),
      ]);
      final mainCopy = await live.copy(phoneFile('pulled').path);
      final walCopy = await File(
        '${live.path}-wal',
      ).copy('${mainCopy.path}-wal-pulled');
      await database.close();

      // ACT
      final withoutWal = reportOf(await importer(database: mainCopy));
      final withWal = reportOf(
        await importer(database: mainCopy, wal: walCopy),
      );

      // ASSERT: WAL nelkul csak a checkpointolt verseny latszik, WAL-lal a
      // masodik is.
      expect(withoutWal.added.map((race) => race.id), ['r1']);
      expect(withWal.updated.map((race) => race.id), ['r1']);
      expect(withWal.added.map((race) => race.id), ['r2']);
    });

    test(
      'ignores an invalid WAL with a warning and imports the main file',
      () async {
        // ARRANGE
        final phone = phoneFile('phone');
        await writePhoneDatabase(phone, [finishedFixtureRace('r1')]);
        final wal = File('${tempDir.path}/bad.sqlite-wal');
        await wal.writeAsString(
          'cat: app_flutter/foretack.sqlite-wal: No such file or directory\n',
        );

        // ACT
        final report = reportOf(await importer(database: phone, wal: wal));

        // ASSERT
        expect(report.warnings, [ImportWarning.walIgnored]);
        expect(report.added.map((race) => race.id), ['r1']);
      },
    );

    test('ignores an empty WAL without a warning', () async {
      final phone = phoneFile('phone');
      await writePhoneDatabase(phone, [finishedFixtureRace('r1')]);
      final wal = await File('${tempDir.path}/empty.sqlite-wal').create();

      final report = reportOf(await importer(database: phone, wal: wal));

      expect(report.warnings, isEmpty);
    });
  });

  group('RaceImporter rejects', () {
    test('a missing main file', () async {
      final result = await importer(database: phoneFile('missing'));

      expect(rejectionOf(result), const MainFileMissing());
    });

    test('a file without the SQLite header', () async {
      final file = await File('${tempDir.path}/text.sqlite').writeAsString(
        'cat: app_flutter/foretack.sqlite: Permission denied\n',
      );

      expect(
        rejectionOf(await importer(database: file)),
        const NotSqliteDatabase(),
      );
    });

    test('an SQLite file that is not a Foretack database', () async {
      // ARRANGE: valodi SQLite-fajl, races tabla nelkul.
      final file = phoneFile('foreign');
      final database = AppDatabase(NativeDatabase(file));
      await database.customStatement('DROP TABLE marks');
      await database.customStatement('DROP TABLE telemetry_records');
      await database.customStatement('DROP TABLE snapshot_logs');
      await database.customStatement('DROP TABLE race_track_stats');
      await database.customStatement('DROP TABLE races');
      await database.close();

      // ACT + ASSERT
      expect(
        rejectionOf(await importer(database: file)),
        const NotForetackDatabase(),
      );
    });

    test('a newer schema, leaving the archive untouched', () async {
      // ARRANGE
      final phone = phoneFile('phone-v99');
      final database = AppDatabase(NativeDatabase(phone));
      await seedRaces(database, [finishedFixtureRace('r1')]);
      await database.customStatement('PRAGMA user_version = 99');
      await database.close();

      // ACT
      final result = await importer(database: phone);

      // ASSERT
      expect(
        rejectionOf(result),
        SchemaTooNew(fileVersion: 99, serverVersion: archive.schemaVersion),
      );
      expect(await RaceRepositoryImpl(archive).getRace('r1'), isNull);
    });
  });

  group('RaceImporter housekeeping', () {
    test('never modifies the uploaded file and removes its work dir', () async {
      // ARRANGE
      final phone = phoneFile('phone-v4');
      final database = AppDatabase(NativeDatabase(phone));
      await seedRaces(database, [finishedFixtureRace('r1')]);
      await database.customStatement('DROP TABLE race_track_stats');
      await database.customStatement('PRAGMA user_version = 4');
      await database.close();
      final before = await phone.readAsBytes();

      // ACT: a migracios ag a legerosebb beavatkozas a masolaton.
      reportOf(await importer(database: phone));

      // ASSERT
      expect(await phone.readAsBytes(), before);
      expect(importTemp.listSync(), isEmpty);
    });

    test('serializes concurrent imports', () async {
      // ARRANGE
      final first = phoneFile('first');
      final second = phoneFile('second');
      await writePhoneDatabase(first, [finishedFixtureRace('r1')]);
      await writePhoneDatabase(second, [finishedFixtureRace('r1')], samples: 5);

      // ACT: ket import egyszerre; a sorositas nelkul a masodik ATTACH a
      // folyamatban levo elso alatt hibara futna.
      final results = await Future.wait([
        importer(database: first),
        importer(database: second),
      ]);

      // ASSERT: a sorrend az erkezesi sorrend, a vegallapot a masodik.
      expect(reportOf(results[0]).added.map((race) => race.id), ['r1']);
      expect(reportOf(results[1]).updated.map((race) => race.id), ['r1']);
      expect(await countRows(archive, 'telemetry_records', 'r1'), 5);
    });
  });
}
