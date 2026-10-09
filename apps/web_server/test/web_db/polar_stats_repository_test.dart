import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

void main() {
  late WebDatabase database;
  late PolarStatsRepository repository;

  final window = OfficialWindow(
    TimeWindow(
      start: DateTime.utc(2026, 7, 26, 9),
      end: DateTime.utc(2026, 7, 26, 11),
    ),
  );
  // A Drift a DateTime-ot masodpercre kerekitve tarolja.
  final computedAt = DateTime.utc(2026, 10, 6, 8);

  CachedPolarStats statsWith(
    Map<int, int> histogram, {
    String fingerprint = 'fp-1',
    StatsWindow? statsWindow,
  }) {
    final seconds = histogram.values.fold(0, (sum, value) => sum + value);
    return CachedPolarStats(
      window: statsWindow ?? window,
      fingerprint: fingerprint,
      performance: PolarPerformance(
        measuredSeconds: seconds,
        pctSecondsSum: seconds * 90.5,
        twsMpsSecondsSum: seconds * 5.5,
        histogram: histogram,
        buckets: {
          5: PolarBucket(seconds: seconds, pctSecondsSum: seconds * 90.5),
        },
        bestFiveSecondsPct: 120.5,
      ),
      computedAt: computedAt,
    );
  }

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    database = WebDatabase(NativeDatabase.memory());
    repository = PolarStatsRepository(database);
  });

  tearDown(() => database.close());

  Future<int> countOf(String table) async =>
      (await database
              .customSelect('SELECT COUNT(*) AS n FROM $table')
              .getSingle())
          .read<int>('n');

  group('PolarStatsRepository', () {
    test('round-trips a race with histogram and wind buckets', () async {
      // ARRANGE
      final stats = statsWith(const {180: 60, 200: 40});

      // ACT
      await repository.put('r1', stats);

      // ASSERT
      expect(await repository.get('r1'), stats);
      expect(await repository.get('nincs'), isNull);
    });

    test('keeps a recording window and an empty race apart', () async {
      // ARRANGE: rogzites-ablak, egyetlen polar-minta nelkul
      final recording = RecordingWindow(window.window);
      final empty = statsWith(const {}, statsWindow: recording);

      // ACT
      await repository.put('r1', empty);

      // ASSERT
      final read = await repository.get('r1');
      expect(read?.window, recording);
      expect(read?.performance.measuredSeconds, 0);
      expect(read?.performance.histogram, isEmpty);
    });

    test('replaces the earlier bins of a race', () async {
      // ARRANGE
      await repository.put('r1', statsWith(const {180: 60, 200: 40}));

      // ACT
      await repository.put('r1', statsWith(const {190: 70}, fingerprint: 'x'));

      // ASSERT
      final read = await repository.get('r1');
      expect(read?.performance.histogram, {190: 70});
      expect(read?.fingerprint, 'x');
      expect(await countOf('race_polar_histogram'), 1);
    });

    test('reads every race at once', () async {
      // ARRANGE
      await repository.put('r1', statsWith(const {180: 60}));
      await repository.put('r2', statsWith(const {200: 80}));

      // ACT
      final all = await repository.getAll();

      // ASSERT
      expect(all.keys, unorderedEquals(['r1', 'r2']));
      expect(all['r2']?.performance.histogram, {200: 80});
    });

    test('deletes a race with its bins and buckets', () async {
      // ARRANGE
      await repository.put('r1', statsWith(const {180: 60}));
      await repository.put('r2', statsWith(const {200: 80}));

      // ACT
      await repository.deleteAll(['r1', 'nincs']);

      // ASSERT
      expect((await repository.getAll()).keys, ['r2']);
      expect(await countOf('race_polar_histogram'), 1);
      expect(await countOf('race_polar_buckets'), 1);
    });

    test('rejects entered values', () {
      expect(
        () => repository.put(
          'r1',
          statsWith(const {}, statsWindow: const ManualEntry()),
        ),
        throwsArgumentError,
      );
    });
  });
}
