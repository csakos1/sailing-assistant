import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

import '../support/archive_fixture.dart';

// A fixture harom pozicios mintaja masodpercenkent: SOG 3, 4, 5 m/s, szel
// 4, 5, 6 m/s 225 fokbol; utana egy minta pozicio, SOG es szel nelkul.

void main() {
  late ArchiveDatabases databases;
  late RaceResultRepository results;
  late RaceStatsRepository stats;
  late RaceStatsRefresher refresher;
  late List<String> logLines;
  final computedAt = DateTime.utc(2026, 10, 1, 9);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    final archive = databases.archive;
    results = RaceResultRepository(databases.web);
    stats = RaceStatsRepository(databases.web);
    logLines = [];
    refresher = RaceStatsRefresher(
      races: RaceRepositoryImpl(archive),
      results: results,
      stats: stats,
      calculate: RaceStatsCalculator(
        readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
        readWindSamples: WindSampleReaderImpl(archive).call,
        now: () => computedAt,
      ),
      log: logLines.add,
    );
  });

  tearDown(() => databases.close());

  final recording = TimeWindow(
    start: archiveStart,
    end: archiveStart.add(const Duration(hours: 2)),
  );

  ImportReport reportOf({List<String> added = const []}) => ImportReport(
    added: [
      for (final id in added)
        ImportedRace(id: id, name: id, finishedAt: recording.end),
    ],
    updated: const [],
    skipped: const [],
    warnings: const [],
  );

  group('RaceStatsRefresher.afterImport', () {
    test('computes the recording window stats of a new race', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      await refresher.afterImport(reportOf(added: ['r1']));

      // ASSERT
      final cached = await stats.get('r1');
      expect(cached?.window, RecordingWindow(recording));
      expect(cached?.track.maxSpeedMps, 5);
      expect(cached?.track.avgSpeedMps, 4);
      expect(cached?.wind.avgWindMps, 5);
      expect(cached?.wind.maxWindMps, 6);
      expect(cached?.wind.directionDeg, closeTo(225, 1e-9));
      expect(cached?.computedAt, computedAt);
    });

    test('uses the official window from a saved result', () async {
      // ARRANGE: the official window holds only the 2nd and 3rd sample
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      await results.upsert(
        'r1',
        RaceResultInput(
          officialStart: archiveStart.add(const Duration(seconds: 1)),
          officialFinish: archiveStart.add(const Duration(seconds: 2)),
        ),
        updatedAt: computedAt,
      );

      // ACT
      await refresher.afterImport(reportOf(added: ['r1']));

      // ASSERT
      final cached = await stats.get('r1');
      expect(cached?.window, isA<OfficialWindow>());
      expect(cached?.track.avgSpeedMps, 4.5);
      expect(cached?.wind.avgWindMps, 5.5);
    });

    test('fills a missing row of a race not in the report', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      await refresher.afterImport(reportOf());

      // ASSERT
      expect(await stats.get('r1'), isNotNull);
    });

    test('keeps a fresh row of a race not in the report', () async {
      // ARRANGE: a deliberately wrong but fresh row must stay untouched
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      final fresh = CachedRaceStats(
        window: RecordingWindow(recording),
        track: const TrackStats(maxSpeedMps: 99),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 9),
      );
      await stats.put('r1', fresh);

      // ACT
      await refresher.afterImport(reportOf());

      // ASSERT
      expect(await stats.get('r1'), fresh);
    });

    test('recomputes a fresh row when the race was re-imported', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      await stats.put(
        'r1',
        CachedRaceStats(
          window: RecordingWindow(recording),
          track: const TrackStats(maxSpeedMps: 99),
          wind: const WindStats(),
          computedAt: DateTime.utc(2026, 9),
        ),
      );

      // ACT
      await refresher.afterImport(reportOf(added: ['r1']));

      // ASSERT
      expect((await stats.get('r1'))?.track.maxSpeedMps, 5);
    });
  });

  group('RaceStatsRefresher.refreshIfStale', () {
    test('does nothing for a race that is not archived', () async {
      await refresher.refreshIfStale('missing');

      expect(await stats.getAll(), isEmpty);
    });

    test('switches to the official window after a result save', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      await refresher.afterImport(reportOf(added: ['r1']));
      await results.upsert(
        'r1',
        RaceResultInput(
          officialStart: archiveStart.add(const Duration(seconds: 1)),
          officialFinish: archiveStart.add(const Duration(seconds: 2)),
        ),
        updatedAt: computedAt,
      );

      // ACT
      await refresher.refreshIfStale('r1');

      // ASSERT
      expect((await stats.get('r1'))?.window, isA<OfficialWindow>());
    });

    test('leaves a row matching the expected window alone', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      final fresh = CachedRaceStats(
        window: RecordingWindow(recording),
        track: const TrackStats(maxSpeedMps: 99),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 9),
      );
      await stats.put('r1', fresh);

      // ACT
      await refresher.refreshIfStale('r1');

      // ASSERT
      expect(await stats.get('r1'), fresh);
    });
  });
}
