import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/race/telemetry_race_deletion_service.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

import '../polar/polar_fixtures.dart';
import '../support/archive_fixture.dart';

// Egy telemetrias verseny torlese (ADR 0057): az archivum sorai a
// CASCADE-dal, a webes sorok egy tranzakcioban. Valodi, fajl-alapu DB-k,
// hogy a PRAGMA foreign_keys is eljen.

void main() {
  late ArchiveDatabases databases;
  late RaceRepositoryImpl races;
  late RaceResultRepository results;
  late RaceStatsRepository stats;
  late PolarStatsRepository polar;
  late List<String> logLines;
  final now = DateTime.utc(2026, 10, 12, 9);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    races = RaceRepositoryImpl(databases.archive);
    results = RaceResultRepository(databases.web);
    stats = RaceStatsRepository(databases.web);
    polar = PolarStatsRepository(databases.web);
    logLines = [];
  });

  tearDown(() => databases.close());

  TelemetryRaceDeletionService serviceWith({
    TransactionRunner? runInWebTransaction,
  }) => TelemetryRaceDeletionService(
    races: races,
    results: results,
    stats: stats,
    polar: polar,
    runInWebTransaction: runInWebTransaction ?? databases.web.transaction,
    lock: SerialLock(),
    log: logLines.add,
  );

  // A verseny a fixture szerint elindult es befejezodott.
  StatsWindow windowOf(Race race) => RecordingWindow(
    TimeWindow(start: race.startedAt!, end: race.finishedAt!),
  );

  Future<void> seedWithWebRows(Race race) async {
    await seedArchiveRace(databases.archive, race);
    await results.upsert(
      race.id,
      const RaceResultInput(overallPlace: FinishPlace(3)),
      updatedAt: now,
    );
    await stats.put(
      race.id,
      CachedRaceStats(
        window: windowOf(race),
        track: const TrackStats(maxSpeedMps: 5),
        wind: const WindStats(),
        computedAt: now,
      ),
    );
    await polar.put(
      race.id,
      CachedPolarStats(
        window: windowOf(race),
        fingerprint: 'fp-1',
        performance: uniformPerformance(seconds: 120, pct: 90),
        computedAt: now,
      ),
    );
  }

  Future<int> snapshotRowsOf(String raceId) async {
    final rows = await (databases.archive.select(
      databases.archive.snapshotLogs,
    )..where((row) => row.raceId.equals(raceId))).get();
    return rows.length;
  }

  test('deletes a finished race with its archive and web rows', () async {
    // ARRANGE
    await seedWithWebRows(finishedArchiveRace('r1'));

    // ACT
    final isDeleted = await serviceWith().delete('r1');

    // ASSERT
    expect(isDeleted, isTrue);
    expect(await races.getRace('r1'), isNull);
    expect(await snapshotRowsOf('r1'), 0);
    expect(await results.get('r1'), isNull);
    expect(await stats.get('r1'), isNull);
    expect(await polar.get('r1'), isNull);
    expect(logLines, isEmpty);
  });

  test('keeps the other races and their rows', () async {
    // ARRANGE
    await seedWithWebRows(finishedArchiveRace('r1'));
    await seedWithWebRows(
      finishedArchiveRace('r2', offset: const Duration(days: 7)),
    );

    // ACT
    await serviceWith().delete('r1');

    // ASSERT
    expect(await races.getRace('r2'), isNotNull);
    expect(await snapshotRowsOf('r2'), greaterThan(0));
    expect(await results.get('r2'), isNotNull);
    expect(await stats.get('r2'), isNotNull);
    expect(await polar.get('r2'), isNotNull);
  });

  test('answers false for an unknown race', () async {
    // ACT
    final isDeleted = await serviceWith().delete('missing');

    // ASSERT
    expect(isDeleted, isFalse);
  });

  test('keeps a race that is not finished', () async {
    // ARRANGE: az import ilyet nem hoz, de a tar elfogadna
    final running = Race.create(
      id: 'r1',
      name: 'Futo',
      marks: const [],
    ).start(at: archiveStart);
    await races.save(running);

    // ACT
    final isDeleted = await serviceWith().delete('r1');

    // ASSERT
    expect(isDeleted, isFalse);
    expect(await races.getRace('r1'), isNotNull);
  });

  test('logs a failed web cleanup and still reports the deletion', () async {
    // ARRANGE
    await seedWithWebRows(finishedArchiveRace('r1'));
    Future<T> failingTransaction<T>(Future<T> Function() action) =>
        Future<T>.error(StateError('web db'));
    final service = serviceWith(runInWebTransaction: failingTransaction);

    // ACT
    final isDeleted = await service.delete('r1');

    // ASSERT
    expect(isDeleted, isTrue);
    expect(await races.getRace('r1'), isNull);
    expect(await results.get('r1'), isNotNull);
    expect(logLines.single, contains('r1'));
  });
}
