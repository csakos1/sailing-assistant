import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/stats/legacy_track_stats_refresher.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

import '../legacy/legacy_track_fixtures.dart';

// A track ot mintaja 10 mp-enkent: SOG 3 m/s, TWS 5 m/s 200 fokbol, 4
// lepes eszak fele, lepesenkent 111,19 m.

void main() {
  late WebDatabase database;
  late ManualRaceRepository manualRaces;
  late RaceResultRepository results;
  late LegacyTrackRepository tracks;
  late RaceStatsRepository stats;
  late LegacyTrackStatsRefresher refresher;
  late List<String> logLines;
  late DateTime now;

  final start = DateTime.utc(2023, 7, 1, 10);
  final finish = start.add(const Duration(minutes: 1));
  final official = OfficialWindow(TimeWindow(start: start, end: finish));
  final day = CalendarDate.tryParse('2023-07-01')!;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = WebDatabase(NativeDatabase.memory());
    manualRaces = ManualRaceRepository(database);
    results = RaceResultRepository(database);
    tracks = LegacyTrackRepository(database);
    stats = RaceStatsRepository(database);
    logLines = [];
    now = DateTime.utc(2026, 10, 5, 9);
    refresher = LegacyTrackStatsRefresher(
      manualRaces: manualRaces,
      results: results,
      tracks: tracks,
      stats: stats,
      calculate: RaceStatsCalculator(
        readTrackSamples: tracks.readWindow,
        readWindSamples: tracks.readWindow,
        now: () => now,
      ),
      log: logLines.add,
    );
  });

  tearDown(() => database.close());

  Future<void> seedRace(String id, {bool hasOfficialTimes = true}) async {
    await manualRaces.insert(
      id,
      ManualRaceInput(name: id, date: day, distanceMeters: 9000),
      now: now,
    );
    if (hasOfficialTimes) {
      await results.upsert(
        id,
        RaceResultInput(officialStart: start, officialFinish: finish),
        updatedAt: now,
      );
    }
    await tracks.replace(id, [
      for (var step = 0; step < 5; step++) legacyStepSample(start, step),
    ]);
  }

  final staleRow = CachedRaceStats(
    window: OfficialWindow(TimeWindow(start: start, end: start)),
    track: const TrackStats(),
    wind: const WindStats(),
    computedAt: DateTime.utc(2026),
  );

  group('refreshAll', () {
    test('computes the official window stats from the track', () async {
      // ARRANGE
      await seedRace('m1');

      // ACT
      await refresher.refreshAll();

      // ASSERT
      final cached = await stats.get('m1');
      expect(cached?.window, official);
      expect(cached?.track.avgSpeedMps, 3);
      expect(cached?.track.maxSpeedMps, 3);
      expect(cached?.track.distanceMeters, closeTo(4 * 111.19, 0.1));
      expect(cached?.wind.avgWindMps, 5);
      expect(cached?.wind.directionDeg, closeTo(200, 1e-9));
      expect(cached?.computedAt, now);
    });

    test('recomputes a fresh row, because the track changed', () async {
      // ARRANGE
      await seedRace('m1');
      await refresher.refreshAll();
      await tracks.replace('m1', [
        for (var step = 0; step < 5; step++)
          legacyStepSample(start, step, sogMps: 4),
      ]);

      // ACT
      await refresher.refreshAll();

      // ASSERT
      expect((await stats.get('m1'))?.track.maxSpeedMps, 4);
    });

    test('drops the row of a race whose track is gone', () async {
      // ARRANGE
      await seedRace('m1');
      await refresher.refreshAll();
      await tracks.delete('m1');

      // ACT
      await refresher.refreshAll();

      // ASSERT
      expect(await stats.get('m1'), isNull);
    });

    test('gives no row to a track without official times', () async {
      // ARRANGE
      await seedRace('m1', hasOfficialTimes: false);

      // ACT
      await refresher.refreshAll();

      // ASSERT
      expect(await stats.get('m1'), isNull);
    });

    test('leaves the telemetry rows alone', () async {
      // ARRANGE: a telemetry race has a row but no manual race record
      await stats.put('t1', staleRow);

      // ACT
      await refresher.refreshAll();

      // ASSERT
      expect(await stats.get('t1'), staleRow);
    });
  });

  group('refreshIfStale', () {
    test('computes a missing row', () async {
      // ARRANGE
      await seedRace('m1');

      // ACT
      await refresher.refreshIfStale('m1');

      // ASSERT
      expect((await stats.get('m1'))?.window, official);
    });

    test('keeps a fresh row', () async {
      // ARRANGE
      await seedRace('m1');
      await refresher.refreshIfStale('m1');
      final first = await stats.get('m1');
      now = now.add(const Duration(hours: 1));

      // ACT
      await refresher.refreshIfStale('m1');

      // ASSERT
      expect(await stats.get('m1'), first);
    });

    test('follows changed official times', () async {
      // ARRANGE: the new window holds only the first three samples
      await seedRace('m1');
      await refresher.refreshIfStale('m1');
      final narrower = start.add(const Duration(seconds: 20));
      await results.upsert(
        'm1',
        RaceResultInput(officialStart: start, officialFinish: narrower),
        updatedAt: now,
      );

      // ACT
      await refresher.refreshIfStale('m1');

      // ASSERT
      final cached = await stats.get('m1');
      expect(
        cached?.window,
        OfficialWindow(TimeWindow(start: start, end: narrower)),
      );
      expect(cached?.track.distanceMeters, closeTo(2 * 111.19, 0.1));
    });

    test('drops the row when the official times are cleared', () async {
      // ARRANGE
      await seedRace('m1');
      await refresher.refreshIfStale('m1');
      await results.delete('m1');

      // ACT
      await refresher.refreshIfStale('m1');

      // ASSERT
      expect(await stats.get('m1'), isNull);
    });

    test('ignores a race that is not a manual race', () async {
      // ARRANGE
      await stats.put('t1', staleRow);

      // ACT
      await refresher.refreshIfStale('t1');

      // ASSERT
      expect(await stats.get('t1'), staleRow);
      expect(logLines, isEmpty);
    });
  });
}
