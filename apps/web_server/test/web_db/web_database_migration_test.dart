import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

// A v1 -> v4 migracio (ADR 0048 D9 + Addendum 3 I2, ADR 0050 D3, ADR
// 0049 D10). A v1 fajlt nyers sqlite3-mal epitjuk, pontosan a v1
// Drift-semaval, hogy a migracio valodi v1-es fajlon fusson, ne a mai
// kodbol generalton.

const _v1Schema = '''
CREATE TABLE race_annotations (
  race_id TEXT NOT NULL,
  overall_place INTEGER NULL,
  overall_fleet_size INTEGER NULL,
  class_place INTEGER NULL,
  class_fleet_size INTEGER NULL,
  summary TEXT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (race_id)
)
''';

void main() {
  late Directory directory;
  late File file;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('foretack_web_v1');
    file = File('${directory.path}/web.sqlite');
    final v1 = sqlite3.open(file.path);
    try {
      v1
        ..execute(_v1Schema)
        ..execute('PRAGMA user_version = 1')
        // 2026-09-30 18:00:00 UTC unix masodpercben, a Drift v1 alakja.
        ..execute(
          'INSERT INTO race_annotations VALUES '
          "('r1', 3, 24, 1, 9, 'Gyenge szel.', 1790791200)",
        );
    } finally {
      v1.close();
    }
  });

  tearDown(() => directory.delete(recursive: true));

  test('copies the v1 annotation into race_results', () async {
    // ARRANGE
    final database = WebDatabase(NativeDatabase(file));
    addTearDown(database.close);

    // ACT
    final result = await RaceResultRepository(database).get('r1');

    // ASSERT
    expect(
      result,
      RaceResult(
        raceId: 'r1',
        content: const RaceResultInput(
          classPlace: FinishPlace(1),
          classFleetSize: 9,
          overallPlace: FinishPlace(3),
          overallFleetSize: 24,
          summary: 'Gyenge szel.',
        ),
        updatedAt: DateTime.utc(2026, 9, 30, 18),
      ),
    );
  });

  test('drops race_annotations and creates the new tables', () async {
    // ARRANGE
    final database = WebDatabase(NativeDatabase(file));
    addTearDown(database.close);

    // ACT
    final rows = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    // ASSERT
    expect(rows.map((row) => row.read<String>('name')), [
      'legacy_track_samples',
      'manual_races',
      'race_polar_buckets',
      'race_polar_histogram',
      'race_polar_stats',
      'race_results',
      'race_stats',
    ]);
  });

  test('sets the schema version to 4', () async {
    final database = WebDatabase(NativeDatabase(file));
    addTearDown(database.close);

    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(version.read<int>('user_version'), 4);
  });

  group('from v2', () {
    late Directory v2Directory;
    late File v2File;

    // A v2 a mai sema a legacy_track_samples es a harom polar-tabla
    // nelkul: a v3 es a v4 csak uj tablakat hoz. Igy a v2-es fajl a mai
    // semabol all elo, negy tabla eldobasaval.
    setUp(() async {
      v2Directory = await Directory.systemTemp.createTemp('foretack_web_v2');
      v2File = File('${v2Directory.path}/web.sqlite');
      final current = WebDatabase(NativeDatabase(v2File));
      await RaceResultRepository(current).upsert(
        'r1',
        const RaceResultInput(overallPlace: FinishPlace(3)),
        updatedAt: DateTime.utc(2026, 10, 2),
      );
      await current.customStatement('DROP TABLE legacy_track_samples');
      await _dropPolarTables(current);
      await current.customStatement('PRAGMA user_version = 2');
      await current.close();
    });

    tearDown(() => v2Directory.delete(recursive: true));

    test('adds legacy_track_samples and keeps the results', () async {
      // ARRANGE
      final database = WebDatabase(NativeDatabase(v2File));
      addTearDown(database.close);

      // ACT
      final result = await RaceResultRepository(database).get('r1');
      final tracks = await database
          .customSelect('SELECT COUNT(*) AS n FROM legacy_track_samples')
          .getSingle();

      // ASSERT
      expect(result?.content.overallPlace, const FinishPlace(3));
      expect(tracks.read<int>('n'), 0);
    });
  });

  group('from v3', () {
    late Directory v3Directory;
    late File v3File;

    // A v3 a mai sema a harom polar-tabla nelkul.
    setUp(() async {
      v3Directory = await Directory.systemTemp.createTemp('foretack_web_v3');
      v3File = File('${v3Directory.path}/web.sqlite');
      final current = WebDatabase(NativeDatabase(v3File));
      await RaceResultRepository(current).upsert(
        'r1',
        const RaceResultInput(overallPlace: FinishPlace(2)),
        updatedAt: DateTime.utc(2026, 10, 6),
      );
      await _dropPolarTables(current);
      await current.customStatement('PRAGMA user_version = 3');
      await current.close();
    });

    tearDown(() => v3Directory.delete(recursive: true));

    test('adds the empty polar cache and keeps the results', () async {
      // ARRANGE
      final database = WebDatabase(NativeDatabase(v3File));
      addTearDown(database.close);

      // ACT
      final result = await RaceResultRepository(database).get('r1');
      final polarRows = await database
          .customSelect('SELECT COUNT(*) AS n FROM race_polar_stats')
          .getSingle();

      // ASSERT
      expect(result?.content.overallPlace, const FinishPlace(2));
      expect(polarRows.read<int>('n'), 0);
    });
  });
}

Future<void> _dropPolarTables(WebDatabase database) async {
  for (final table in [
    'race_polar_stats',
    'race_polar_histogram',
    'race_polar_buckets',
  ]) {
    await database.customStatement('DROP TABLE $table');
  }
}
