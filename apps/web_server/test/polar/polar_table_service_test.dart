import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_table_service.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

import '../support/archive_fixture.dart';
import 'polar_fixtures.dart';

// Harom telemetrias verseny 2026-ban, egy-egy nap kulonbseggel:
// - 'fast': 100 mp 95%-on, friss sor;
// - 'slow': 300 mp 90%-on, elavult ujjlenyomattal;
// - 'none': nincs sora.

void main() {
  late ArchiveDatabases databases;
  late PolarStatsRepository repository;
  late PolarTableService service;
  final computedAt = DateTime.utc(2026, 10, 6, 8);
  final recording = RecordingWindow(
    TimeWindow(
      start: archiveStart,
      end: archiveStart.add(const Duration(hours: 2)),
    ),
  );

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    repository = PolarStatsRepository(databases.web);
    service = PolarTableService(
      catalog: PolarRaceCatalog(
        races: RaceRepositoryImpl(databases.archive),
        results: RaceResultRepository(databases.web),
        manualRaces: ManualRaceRepository(databases.web),
        tracks: LegacyTrackRepository(databases.web),
      ),
      repository: repository,
      fingerprint: 'fp-1',
    );
    final races = RaceRepositoryImpl(databases.archive);
    for (final (index, id) in ['fast', 'slow', 'none'].indexed) {
      await races.save(
        finishedArchiveRace(id, offset: Duration(days: index)),
      );
    }
    await repository.put(
      'fast',
      CachedPolarStats(
        window: recording,
        fingerprint: 'fp-1',
        performance: uniformPerformance(seconds: 100, pct: 95),
        computedAt: computedAt,
      ),
    );
    await repository.put(
      'slow',
      CachedPolarStats(
        window: RecordingWindow(
          TimeWindow(
            start: archiveStart.add(const Duration(days: 1)),
            end: archiveStart.add(const Duration(days: 1, hours: 2)),
          ),
        ),
        fingerprint: 'old',
        performance: uniformPerformance(seconds: 300, pct: 90),
        computedAt: computedAt,
      ),
    );
  });

  tearDown(() => databases.close());

  group('PolarTableService.season', () {
    test('lists the races by date with cache state and rank', () async {
      // ACT
      final table = await service.season(2026);

      // ASSERT
      expect(
        [for (final row in table.rows) row.raceId],
        [
          'fast',
          'slow',
          'none',
        ],
      );
      expect(
        [for (final row in table.rows) row.cacheState],
        [
          PolarCacheState.fresh,
          PolarCacheState.stale,
          PolarCacheState.missing,
        ],
      );
      expect([for (final row in table.rows) row.rank], [1, 2, null]);
      expect(table.rows.last.stats, isNull);
      expect(table.rows.first.isApproximate, isTrue);
      expect(table.rows.first.elapsed, const Duration(hours: 2));
      expect(table.rankedCount, 2);
      expect(table.isStale, isTrue);
    });

    test('adds the race average and the time-weighted row', () async {
      // ACT
      final table = await service.season(2026);

      // ASSERT: futamok atlaga (95 + 90) / 2; idore sulyozva
      // (100 x 95 + 300 x 90) / 400
      expect(table.raceAverage?.avgPct, 92.5);
      expect(table.raceAverage?.measuredSeconds, 400);
      expect(table.raceAverage?.avgTwsMps, isNull);
      expect(table.timeWeighted?.avgPct, 91.25);
      expect(table.timeWeighted?.avgTwsMps, 5);
      // a 400 mp medianja a 90%-os resbe esik
      expect(table.timeWeighted?.medianPct, 90.25);
    });

    test('gives an empty table for a year without races', () async {
      // ACT
      final table = await service.season(2025);

      // ASSERT
      expect(table.rows, isEmpty);
      expect(table.raceAverage, isNull);
      expect(table.timeWeighted, isNull);
      expect(table.rankedCount, 0);
    });
  });

  group('PolarTableService.seasons', () {
    test('gives the time-weighted row of every year', () async {
      // ACT
      final seasons = await service.seasons();

      // ASSERT
      expect(seasons, hasLength(1));
      expect(seasons.single.year, 2026);
      expect(seasons.single.raceCount, 2);
      expect(seasons.single.timeWeighted?.avgPct, 91.25);
    });
  });

  group('PolarTableService.race', () {
    test('gives the row with the season rank', () async {
      // ACT
      final detail = await service.race('slow');

      // ASSERT
      expect(detail?.row.rank, 2);
      expect(detail?.rankedCount, 2);
      expect(detail?.row.cacheState, PolarCacheState.stale);
    });

    test('gives nothing for a race without a polar source', () async {
      expect(await service.race('nincs'), isNull);
    });
  });
}
