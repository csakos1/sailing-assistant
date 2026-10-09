import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_reference.dart';
import 'package:web_server/src/polar/polar_stats_calculator.dart';
import 'package:web_server/src/polar/polar_stats_refresher.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

import '../support/archive_fixture.dart';
import 'polar_fixtures.dart';

// A mintak hamis olvasokbol jonnek, a versenyek es a cache valodi DB-kbol.
// Az alapminta TWA 60, TWS 10 kn, STW 4 kn: 80% az egyszeru polaron.

void main() {
  late ArchiveDatabases databases;
  late PolarRaceCatalog catalog;
  late PolarStatsRepository repository;
  late Map<String, List<PolarSample>> telemetrySamples;
  late Map<String, List<PolarSample>> legacySamples;
  late List<String> readRaces;
  late List<String> logLines;
  final now = DateTime.utc(2026, 10, 6, 8);
  final manualStart = DateTime.utc(2023, 7, 1, 10);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    catalog = PolarRaceCatalog(
      races: RaceRepositoryImpl(databases.archive),
      results: RaceResultRepository(databases.web),
      manualRaces: ManualRaceRepository(databases.web),
      tracks: LegacyTrackRepository(databases.web),
    );
    repository = PolarStatsRepository(databases.web);
    telemetrySamples = {};
    legacySamples = {};
    readRaces = [];
    logLines = [];
  });

  tearDown(() => databases.close());

  PolarStatsRefresher refresherWith(PolarReference reference) =>
      PolarStatsRefresher(
        catalog: catalog,
        repository: repository,
        calculate: PolarStatsCalculator(
          readTelemetrySamples: (raceId, window) async {
            readRaces.add(raceId);
            if (raceId == 'bad') throw StateError('serult minta');
            return telemetrySamples[raceId] ?? const [];
          },
          readLegacySamples: (raceId, window) async {
            readRaces.add(raceId);
            return legacySamples[raceId] ?? const [];
          },
          reference: reference,
          now: () => now,
        ),
        log: logLines.add,
      );

  ImportReport reportOf({List<String> added = const []}) => ImportReport(
    added: [
      for (final id in added)
        ImportedRace(
          id: id,
          name: id,
          finishedAt: archiveStart.add(const Duration(hours: 2)),
        ),
    ],
    updated: const [],
    skipped: const [],
    warnings: const [],
  );

  Future<void> seedTelemetry(String id) async {
    await seedArchiveRace(databases.archive, finishedArchiveRace(id));
    telemetrySamples[id] = steadySamples(archiveStart, 60);
  }

  // Trackes kezi verseny hivatalos idovel, hat 10 mp-es mintaval.
  Future<void> seedLegacy(String id) async {
    await ManualRaceRepository(databases.web).insert(
      id,
      // A `!` biztonsagos: letezo nap.
      ManualRaceInput(name: id, date: CalendarDate.tryParse('2023-07-01')!),
      now: now,
    );
    await LegacyTrackRepository(
      databases.web,
    ).replace(id, [LegacyTrackSample(timestamp: manualStart)]);
    await RaceResultRepository(databases.web).upsert(
      id,
      RaceResultInput(
        officialStart: manualStart,
        officialFinish: manualStart.add(const Duration(hours: 1)),
      ),
      updatedAt: now,
    );
    legacySamples[id] = steadySamples(manualStart, 6, durationSeconds: 10);
  }

  group('PolarStatsRefresher.afterImport', () {
    test('computes a new telemetry race', () async {
      // ARRANGE
      await seedTelemetry('r1');

      // ACT
      await refresherWith(flatReference()).afterImport(reportOf(added: ['r1']));

      // ASSERT
      final cached = await repository.get('r1');
      expect(cached?.fingerprint, 'fp-1');
      expect(cached?.window, isA<RecordingWindow>());
      expect(cached?.performance.measuredSeconds, 60);
      expect(cached?.performance.averagePct, closeTo(80, 1e-9));
      expect(cached?.computedAt, now);
    });

    test('skips a fresh race that the import did not change', () async {
      // ARRANGE
      await seedTelemetry('r1');
      final refresher = refresherWith(flatReference());
      await refresher.refreshAllStale();

      // ACT
      await refresher.afterImport(reportOf());

      // ASSERT
      expect(readRaces, ['r1']);
    });

    test('recomputes a fresh race that the import changed', () async {
      // ARRANGE
      await seedTelemetry('r1');
      final refresher = refresherWith(flatReference());
      await refresher.refreshAllStale();

      // ACT
      await refresher.afterImport(reportOf(added: ['r1']));

      // ASSERT
      expect(readRaces, ['r1', 'r1']);
    });

    test('keeps going after a failing race', () async {
      // ARRANGE
      await seedTelemetry('bad');
      await seedTelemetry('r1');

      // ACT
      await refresherWith(
        flatReference(),
      ).afterImport(reportOf(added: ['bad', 'r1']));

      // ASSERT
      expect(await repository.get('bad'), isNull);
      expect(await repository.get('r1'), isNotNull);
      expect(logLines, contains(startsWith('polár-számítás sikertelen (bad)')));
    });
  });

  group('PolarStatsRefresher.refreshIfStale', () {
    test('recomputes a race after a polar change', () async {
      // ARRANGE
      await seedTelemetry('r1');
      await refresherWith(flatReference()).refreshAllStale();

      // ACT
      await refresherWith(
        flatReference(fingerprint: 'fp-2'),
      ).refreshIfStale('r1');

      // ASSERT
      expect((await repository.get('r1'))?.fingerprint, 'fp-2');
    });

    test('leaves a fresh race alone', () async {
      // ARRANGE
      await seedTelemetry('r1');
      final refresher = refresherWith(flatReference());
      await refresher.refreshAllStale();

      // ACT
      await refresher.refreshIfStale('r1');

      // ASSERT
      expect(readRaces, ['r1']);
    });

    test('does nothing for a race without a polar source', () async {
      // ACT
      await refresherWith(flatReference()).refreshIfStale('nincs');

      // ASSERT
      expect(await repository.getAll(), isEmpty);
      expect(readRaces, isEmpty);
    });
  });

  group('PolarStatsRefresher.refreshAllStale', () {
    test('corrects only the telemetry water speed', () async {
      // ARRANGE: 1,25-os szorzo 2000 ota; 4 kn x 1,25 = 5 kn -> 100%
      await seedTelemetry('r1');
      await seedLegacy('m1');
      final reference = flatReference(
        corrections: [StwCorrection(from: DateTime.utc(2000), factor: 1.25)],
      );

      // ACT
      await refresherWith(reference).refreshAllStale();

      // ASSERT
      final telemetry = await repository.get('r1');
      final legacy = await repository.get('m1');
      expect(telemetry?.performance.averagePct, closeTo(100, 1e-9));
      expect(legacy?.performance.averagePct, closeTo(80, 1e-9));
      expect(legacy?.performance.measuredSeconds, 60);
      expect(legacy?.window, isA<OfficialWindow>());
    });

    test('deletes the rows of races that are gone', () async {
      // ARRANGE
      await seedTelemetry('r1');
      final refresher = refresherWith(flatReference());
      await refresher.refreshAllStale();
      final orphan = await repository.get('r1');
      // A `!` biztonsagos: az elozo frissites irta.
      await repository.put('gone', orphan!);

      // ACT
      await refresher.refreshAllStale();

      // ASSERT
      expect((await repository.getAll()).keys, ['r1']);
      expect(readRaces, ['r1']);
    });
  });
}
