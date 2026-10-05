import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

import '../legacy/legacy_track_fixtures.dart';

void main() {
  late WebDatabase database;
  late LegacyTrackRepository repository;
  final start = DateTime.utc(2023, 7, 1, 10);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = WebDatabase(NativeDatabase.memory());
    repository = LegacyTrackRepository(database);
  });

  tearDown(() => database.close());

  test('round-trips every field of a sample', () async {
    // ARRANGE
    final sample = legacyStepSample(start, 0);

    // ACT
    await repository.replace('m1', [sample]);

    // ASSERT
    expect(await repository.readWindow('m1', null), [sample]);
  });

  test('keeps the empty fields empty', () async {
    // ARRANGE
    final sample = legacyStepSample(
      start,
      0,
      sogMps: null,
      twsMps: null,
      twdDeg: null,
      hasPosition: false,
    );

    // ACT
    await repository.replace('m1', [sample]);

    // ASSERT
    expect(await repository.readWindow('m1', null), [sample]);
  });

  test('reads in time order, the window bounds included', () async {
    // ARRANGE: stored in reverse order
    await repository.replace('m1', [
      for (var step = 4; step >= 0; step--) legacyStepSample(start, step),
    ]);
    final window = TimeWindow(
      start: start.add(const Duration(seconds: 10)),
      end: start.add(const Duration(seconds: 30)),
    );

    // ACT
    final samples = await repository.readWindow('m1', window);

    // ASSERT
    expect(
      [for (final sample in samples) sample.timestamp],
      [
        start.add(const Duration(seconds: 10)),
        start.add(const Duration(seconds: 20)),
        start.add(const Duration(seconds: 30)),
      ],
    );
  });

  test('reads only the samples of the asked race', () async {
    // ARRANGE
    await repository.replace('m1', [legacyStepSample(start, 0)]);
    await repository.replace('m2', [legacyStepSample(start, 1)]);

    // ACT
    final samples = await repository.readWindow('m2', null);

    // ASSERT
    expect(samples, [legacyStepSample(start, 1)]);
  });

  test('replaces the previous track', () async {
    // ARRANGE
    await repository.replace('m1', [
      legacyStepSample(start, 0),
      legacyStepSample(start, 1),
    ]);

    // ACT
    await repository.replace('m1', [legacyStepSample(start, 5)]);

    // ASSERT
    expect(await repository.readWindow('m1', null), [
      legacyStepSample(start, 5),
    ]);
  });

  test('an empty replacement removes the track', () async {
    // ARRANGE
    await repository.replace('m1', [legacyStepSample(start, 0)]);

    // ACT
    await repository.replace('m1', const []);

    // ASSERT
    expect(await repository.hasTrack('m1'), isFalse);
  });

  test('deletes only the asked track', () async {
    // ARRANGE
    await repository.replace('m1', [legacyStepSample(start, 0)]);
    await repository.replace('m2', [legacyStepSample(start, 0)]);

    // ACT
    await repository.delete('m1');

    // ASSERT
    expect(await repository.raceIdsWithTrack(), {'m2'});
    expect(await repository.hasTrack('m1'), isFalse);
    expect(await repository.hasTrack('m2'), isTrue);
  });
}
