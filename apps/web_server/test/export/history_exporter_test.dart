import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:web_server/src/export/database_snapshot.dart';
import 'package:web_server/src/export/export_bundle.dart';
import 'package:web_server/src/export/history_exporter.dart';
import 'package:web_server/src/export/vacuum_into.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';

import '../support/archive_fixture.dart';
import 'tar_reader.dart';

// Az export a valodi lancon: VACUUM INTO a ket teszt-DB-rol, JSON a
// masolatokbol, tar.gz a munkakonyvtarba. A csomagot a teszt bontja ki.

const _base = 'foretack-history-2026-10-06';

void main() {
  late ArchiveDatabases databases;
  late Directory tempRoot;
  late SerialLock lock;
  late List<String> logLines;
  final exportedAt = DateTime.utc(2026, 10, 6, 9, 30);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    tempRoot = await Directory('${databases.directory.path}/tmp').create();
    lock = SerialLock();
    logLines = [];
  });

  tearDown(() => databases.close());

  HistoryExporter exporter({
    Future<void> Function(String path)? snapshotArchive,
  }) => HistoryExporter(
    tempRoot: tempRoot,
    lock: lock,
    snapshotArchive:
        snapshotArchive ?? ((path) => vacuumInto(databases.archive, path)),
    snapshotWebDatabase: (path) => vacuumInto(databases.web, path),
    openSnapshot: openDatabaseSnapshot,
    archiveSchemaVersion: databases.archive.schemaVersion,
    webSchemaVersion: databases.web.schemaVersion,
    serverVersion: '9.9.9',
    now: () => exportedAt,
    log: logLines.add,
  );

  Future<ExportBundle> exportOk(HistoryExporter export) async =>
      switch (await export()) {
        Ok(:final value) => value,
        Err(:final error) => fail('$error'),
      };

  Future<List<int>> readAll(ExportBundle bundle) async {
    final bytes = <int>[];
    await bundle.read().forEach(bytes.addAll);
    return bytes;
  }

  Future<void> seedBothKinds() async {
    await seedArchiveRace(databases.archive, finishedArchiveRace('t-1'));
    await ManualRaceRepository(databases.web).insert(
      'm-1',
      ManualRaceInput(
        name: 'Kezi',
        // Ervenyes nap szovegebol: a parse itt nem lehet null.
        date: CalendarDate.tryParse('2023-07-01')!,
      ),
      now: exportedAt,
    );
  }

  test('packs the readme, the json and both databases', () async {
    await seedBothKinds();

    final bundle = await exportOk(exporter());
    final bytes = await readAll(bundle);
    final entries = readTarGz(bytes);

    expect(bundle.fileName, '$_base.tar.gz');
    expect(bundle.length, bytes.length);
    expect(entries.keys, [
      '$_base/README.txt',
      '$_base/foretack-history.json',
      '$_base/archive.sqlite',
      '$_base/web.sqlite',
    ]);
    expect(
      utf8.decode(entries['$_base/README.txt']!),
      contains('Versenyek:     2'),
    );
  });

  test('describes every race in the json with the contract codec', () async {
    await seedBothKinds();

    final entries = readTarGz(await readAll(await exportOk(exporter())));
    final json =
        jsonDecode(utf8.decode(entries['$_base/foretack-history.json']!))
            as Map<String, Object?>;
    final ids = <String>{
      for (final race in json['races']! as List<Object?>)
        switch (decodeRaceDetail(race)) {
          Ok(:final value) => value.summary.id,
          Err(:final error) => fail('$error'),
        },
    };

    expect(json['exportedAt'], '2026-10-06T09:30:00.000Z');
    expect(ids, {'t-1', 'm-1'});
  });

  test('ships databases that open and hold the rows', () async {
    await seedBothKinds();
    final entries = readTarGz(await readAll(await exportOk(exporter())));
    final archiveFile = File('${databases.directory.path}/out-archive.sqlite')
      ..writeAsBytesSync(entries['$_base/archive.sqlite']!);
    final webFile = File('${databases.directory.path}/out-web.sqlite')
      ..writeAsBytesSync(entries['$_base/web.sqlite']!);

    final archive = sqlite3.open(archiveFile.path);
    final web = sqlite3.open(webFile.path);
    addTearDown(archive.close);
    addTearDown(web.close);

    expect(archive.select('SELECT id FROM races').single['id'], 't-1');
    expect(web.select('SELECT id FROM manual_races').single['id'], 'm-1');
  });

  test('refuses a second export until the first is streamed', () async {
    final export = exporter();
    final first = await exportOk(export);

    final second = await export();
    await readAll(first);
    final third = await export();

    expect(
      second,
      const Err<ExportBundle, ExportInProgress>(ExportInProgress()),
    );
    expect(third, isA<Ok<ExportBundle, ExportInProgress>>());
    if (third case Ok(:final value)) await readAll(value);
  });

  test('removes its work directory after streaming', () async {
    await readAll(await exportOk(exporter()));

    expect(tempRoot.listSync(), isEmpty);
  });

  test('cleans up and frees the export on a cancelled download', () async {
    final export = exporter();
    final bundle = await exportOk(export);
    final firstChunk = Completer<void>();
    final subscription = bundle.read().listen((_) {
      if (!firstChunk.isCompleted) firstChunk.complete();
    });

    await firstChunk.future;
    await subscription.cancel();

    expect(tempRoot.listSync(), isEmpty);
    final next = await export();
    expect(next, isA<Ok<ExportBundle, ExportInProgress>>());
    if (next case Ok(:final value)) await readAll(value);
  });

  test('cleans up and frees the export when a snapshot fails', () async {
    final export = exporter(
      snapshotArchive: (_) async => throw StateError('disk full'),
    );

    await expectLater(export(), throwsStateError);

    expect(tempRoot.listSync(), isEmpty);
    await expectLater(export(), throwsStateError);
  });
}
