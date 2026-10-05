import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_track_applier.dart';
import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

import 'legacy_track_fixtures.dart';

void main() {
  late WebDatabase database;
  late LegacyTrackRepository tracks;
  late int refreshCount;
  late LegacyTrackApplier applier;
  final start = DateTime.utc(2023, 7, 1, 10);
  final window = TimeWindow(
    start: start,
    end: start.add(const Duration(minutes: 1)),
  );

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = WebDatabase(NativeDatabase.memory());
    tracks = LegacyTrackRepository(database);
    refreshCount = 0;
    applier = LegacyTrackApplier(
      tracks: tracks,
      runInTransaction: database.transaction,
      refreshStats: () async => refreshCount++,
    );
  });

  tearDown(() => database.close());

  PlannedLegacyTrack planned(String id, List<int> steps) => PlannedLegacyTrack(
    legacyManualRecord(id),
    window: window,
    samples: [for (final step in steps) legacyStepSample(start, step)],
    coverage: 1,
    distanceMeters: 100,
  );

  test('writes the planned tracks and refreshes the stats once', () async {
    // ACT
    final report = await applier([
      planned('m1', [0, 1, 2]),
    ]);

    // ASSERT
    expect(report, (written: 1, cleared: 0));
    expect(await tracks.readWindow('m1', null), hasLength(3));
    expect(refreshCount, 1);
  });

  test('removes the earlier track of a race without one now', () async {
    // ARRANGE
    await tracks.replace('m1', [legacyStepSample(start, 0)]);
    await tracks.replace('m2', [legacyStepSample(start, 0)]);

    // ACT
    final report = await applier([
      LegacyTrackWithoutWindow(legacyManualRecord('m1')),
      LegacyTrackTooShort(
        legacyManualRecord('m2'),
        window: window,
        sampleCount: 1,
        positionCount: 1,
      ),
    ]);

    // ASSERT
    expect(report, (written: 0, cleared: 2));
    expect(await tracks.raceIdsWithTrack(), isEmpty);
  });

  test('gives the same state when run twice', () async {
    // ARRANGE
    final plan = [
      planned('m1', [0, 1, 2]),
    ];
    await applier(plan);

    // ACT
    await applier(plan);

    // ASSERT
    expect(await tracks.readWindow('m1', null), [
      for (final step in [0, 1, 2]) legacyStepSample(start, step),
    ]);
  });
}
