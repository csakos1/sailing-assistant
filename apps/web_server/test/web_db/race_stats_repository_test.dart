import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  late RaceStatsRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    repository = RaceStatsRepository(databases.web);
  });

  tearDown(() => databases.close());

  final window = TimeWindow(
    start: DateTime.utc(2026, 7, 26, 9, 0, 0, 250),
    end: DateTime.utc(2026, 7, 26, 14, 24),
  );
  final stats = CachedRaceStats(
    window: OfficialWindow(window),
    track: const TrackStats(
      maxSpeedMps: 4.1,
      avgSpeedMps: 2.3,
      distanceMeters: 22600,
    ),
    wind: const WindStats(avgWindMps: 2.5, maxWindMps: 4.9, directionDeg: 310),
    computedAt: DateTime.utc(2026, 10, 1, 9),
  );

  group('RaceStatsRepository', () {
    test('round-trips the window bounds to the millisecond', () async {
      // ACT
      await repository.put('r1', stats);

      // ASSERT
      expect(await repository.get('r1'), stats);
    });

    test('tells a recording window from an official one', () async {
      // ARRANGE
      final recording = CachedRaceStats(
        window: RecordingWindow(window),
        track: const TrackStats(),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 10, 1, 9),
      );

      // ACT
      await repository.put('r1', recording);

      // ASSERT
      expect((await repository.get('r1'))?.window, RecordingWindow(window));
    });

    test('replaces the previous row', () async {
      // ARRANGE
      await repository.put('r1', stats);
      final recomputed = CachedRaceStats(
        window: RecordingWindow(window),
        track: const TrackStats(maxSpeedMps: 5),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 10, 2, 9),
      );

      // ACT
      await repository.put('r1', recomputed);

      // ASSERT
      expect(await repository.getAll(), {'r1': recomputed});
    });

    test('refuses a manual window, which has no cache', () async {
      final manual = CachedRaceStats(
        window: const ManualEntry(),
        track: const TrackStats(),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 10, 1, 9),
      );

      await expectLater(repository.put('m1', manual), throwsArgumentError);
    });

    test('deletes only the asked row', () async {
      // ARRANGE
      await repository.put('r1', stats);
      await repository.put('r2', stats);

      // ACT
      await repository.delete('r1');

      // ASSERT
      expect(await repository.getAll(), {'r2': stats});
    });

    test('deleting a missing row is not an error', () async {
      await repository.delete('missing');

      expect(await repository.getAll(), isEmpty);
    });
  });

  group('CachedRaceStats.toRaceStats', () {
    test('maps the direction in degrees to a compass point', () {
      final raceStats = stats.toRaceStats();

      expect(raceStats.windPoint, CompassPoint.northWest);
      expect(raceStats.avgWindMps, 2.5);
      expect(raceStats.track.distanceMeters, 22600);
      expect(raceStats.window, OfficialWindow(window));
    });

    test('leaves the compass point empty without a direction', () {
      final raceStats = CachedRaceStats(
        window: OfficialWindow(window),
        track: const TrackStats(),
        wind: const WindStats(avgWindMps: 2),
        computedAt: DateTime.utc(2026, 10, 1, 9),
      ).toRaceStats();

      expect(raceStats.windPoint, isNull);
    });
  });
}
