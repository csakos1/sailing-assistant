import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/race/manual_race_service.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

import '../legacy/legacy_track_fixtures.dart';

// A kezi verseny mentese es torlese a regi track korul (ADR 0050 Addendum
// 1 E2). A frissito itt csak naplozza a hivasokat; a sajat tesztje a
// legacy_track_stats_refresher_test.

void main() {
  late WebDatabase database;
  late LegacyTrackRepository tracks;
  late RaceStatsRepository stats;
  late RaceResultRepository results;
  late List<String> refreshedIds;
  late ManualRaceService service;
  final start = DateTime.utc(2023, 7, 1, 10);
  final day = CalendarDate.tryParse('2023-07-01')!;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = WebDatabase(NativeDatabase.memory());
    tracks = LegacyTrackRepository(database);
    stats = RaceStatsRepository(database);
    results = RaceResultRepository(database);
    refreshedIds = [];
    service = ManualRaceService(
      manualRaces: ManualRaceRepository(database),
      results: results,
      tracks: tracks,
      stats: stats,
      runInTransaction: database.transaction,
      lock: SerialLock(),
      refreshStats: (raceId) async => refreshedIds.add(raceId),
      newId: () => 'm1',
      now: () => DateTime.utc(2026, 10, 5, 9),
    );
  });

  tearDown(() => database.close());

  ManualRaceRequest request({DateTime? officialStart}) => ManualRaceRequest(
    race: ManualRaceInput(name: 'Kekszalag', date: day),
    result: RaceResultInput(officialStart: officialStart),
  );

  test('refreshes the stats of a saved race', () async {
    // ARRANGE
    await service.create(request());

    // ACT
    await service.update('m1', request(officialStart: start));

    // ASSERT
    expect(refreshedIds, ['m1']);
  });

  test('does not refresh when the race does not exist', () async {
    // ACT
    final summary = await service.update('missing', request());

    // ASSERT
    expect(summary, isNull);
    expect(refreshedIds, isEmpty);
  });

  test('deletes the track and the stats row with the race', () async {
    // ARRANGE
    await service.create(request(officialStart: start));
    await tracks.replace('m1', [legacyStepSample(start, 0)]);
    await stats.put(
      'm1',
      CachedRaceStats(
        window: OfficialWindow(TimeWindow(start: start, end: start)),
        track: const TrackStats(),
        wind: const WindStats(),
        computedAt: DateTime.utc(2026, 10, 5),
      ),
    );

    // ACT
    final isDeleted = await service.delete('m1');

    // ASSERT
    expect(isDeleted, isTrue);
    expect(await results.get('m1'), isNull);
    expect(await tracks.hasTrack('m1'), isFalse);
    expect(await stats.get('m1'), isNull);
  });

  test('keeps the other tracks when the race does not exist', () async {
    // ARRANGE
    await tracks.replace('m2', [legacyStepSample(start, 0)]);

    // ACT
    final isDeleted = await service.delete('missing');

    // ASSERT
    expect(isDeleted, isFalse);
    expect(await tracks.hasTrack('m2'), isTrue);
  });
}
