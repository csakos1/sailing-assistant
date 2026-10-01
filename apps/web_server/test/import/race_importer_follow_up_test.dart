import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/serial_lock.dart';

import 'phone_database_fixture.dart';

// Az import utani lepes es a kozos zar (ADR 0048 Addendum 3 I4, I5).

void main() {
  late Directory tempDir;
  late AppDatabase archive;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('foretack_follow_up');
    archive = AppDatabase(
      NativeDatabase(File('${tempDir.path}/archive.sqlite')),
    );
  });

  tearDown(() async {
    await archive.close();
    await tempDir.delete(recursive: true);
  });

  Future<File> phoneWith(String raceId) async {
    final phone = File('${tempDir.path}/$raceId.sqlite');
    await writePhoneDatabase(phone, [finishedFixtureRace(raceId)]);
    return phone;
  }

  test('runs the follow-up with the report after a merge', () async {
    // ARRANGE
    final reports = <ImportReport>[];
    final importer = RaceImporter(
      archive: archive,
      tempRoot: tempDir,
      afterMerge: (report) async => reports.add(report),
    );

    // ACT
    await importer(database: await phoneWith('r1'));

    // ASSERT
    expect(reports.single.added.map((race) => race.id), ['r1']);
  });

  test('skips the follow-up when the upload is rejected', () async {
    // ARRANGE
    final reports = <ImportReport>[];
    final importer = RaceImporter(
      archive: archive,
      tempRoot: tempDir,
      afterMerge: (report) async => reports.add(report),
    );
    final notSqlite = File('${tempDir.path}/text.sqlite')
      ..writeAsStringSync('ez nem adatbazis');

    // ACT
    final result = await importer(database: notSqlite);

    // ASSERT
    expect(result, isA<Err<ImportReport, ImportRejection>>());
    expect(reports, isEmpty);
  });

  test('waits for a task already holding the shared lock', () async {
    // ARRANGE: a zarat egy masik iro (pl. eredmeny-mentes) tartja
    final lock = SerialLock();
    final events = <String>[];
    final importer = RaceImporter(
      archive: archive,
      tempRoot: tempDir,
      lock: lock,
      afterMerge: (report) async => events.add('import'),
    );
    final phone = await phoneWith('r1');
    final holder = lock.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      events.add('holder');
    });

    // ACT
    await Future.wait([holder, importer(database: phone)]);

    // ASSERT
    expect(events, ['holder', 'import']);
  });
}
