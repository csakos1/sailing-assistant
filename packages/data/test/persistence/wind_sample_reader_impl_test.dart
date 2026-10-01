import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SnapshotLoggerImpl logger;
  late WindSampleReaderImpl reader;

  // A snapshot a valodi RaceSnapshot.toJson alakban kerul a sorba, igy a
  // teszt a tenyleges JSON-szerkezeten igazolja a json_extract utvonalait.
  RaceSnapshot snapshotAt(
    DateTime t, {
    double? twsMps,
    Bearing? twd,
    bool hasWind = true,
  }) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: t),
    connectionStatus: const Connected(),
    tickTime: t,
    wind: hasWind
        ? WindData(
            apparentAngle: const Angle(degrees: 30),
            apparentSpeed: const Speed(metersPerSecond: 6),
            timestamp: t,
            trueSpeedWater: twsMps == null
                ? null
                : Speed(metersPerSecond: twsMps),
            trueDirectionGround: twd,
          )
        : null,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(db);
    reader = WindSampleReaderImpl(db);
    // A snapshot_logs.raceId idegen kulcsa miatt kell egy race-sor.
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-1',
            name: 'Teszt',
            statusIndex: RaceStatus.finished,
            createdAt: DateTime(2026, 5, 1, 10),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('reads true wind speed and true-north direction', () async {
    // ARRANGE
    await logger.log(
      'race-1',
      snapshotAt(
        DateTime.utc(2026, 5, 1, 10, 0, 1),
        twsMps: 5.5,
        twd: const Bearing.true_(225),
      ),
    );

    // ACT
    final sample = (await reader('race-1', null)).single;

    // ASSERT
    expect(sample.twsMps, 5.5);
    expect(sample.twdDeg, 225);
  });

  test('drops a magnetic direction but keeps the speed', () async {
    // ARRANGE - deklinacio nelkul a magneses irany nem valthato at.
    await logger.log(
      'race-1',
      snapshotAt(
        DateTime.utc(2026, 5, 1, 10, 0, 1),
        twsMps: 4,
        twd: const Bearing(
          degrees: 200,
          reference: BearingReference.magneticNorth,
        ),
      ),
    );

    // ACT
    final sample = (await reader('race-1', null)).single;

    // ASSERT
    expect(sample.twsMps, 4);
    expect(sample.twdDeg, isNull);
  });

  test('returns nulls for a snapshot without wind', () async {
    // ARRANGE
    await logger.log(
      'race-1',
      snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 1), hasWind: false),
    );

    // ACT
    final sample = (await reader('race-1', null)).single;

    // ASSERT
    expect(sample.twsMps, isNull);
    expect(sample.twdDeg, isNull);
  });

  test('filters by the window, bounds included, in time order', () async {
    // ARRANGE - forditott sorrendben irjuk be oket.
    for (final (second, tws) in [(5, 5.0), (4, 4.0), (2, 2.0), (1, 1.0)]) {
      await logger.log(
        'race-1',
        snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, second), twsMps: tws),
      );
    }
    final window = TimeWindow(
      start: DateTime.utc(2026, 5, 1, 10, 0, 2),
      end: DateTime.utc(2026, 5, 1, 10, 0, 4),
    );

    // ACT
    final samples = await reader('race-1', window);

    // ASSERT
    expect([for (final s in samples) s.twsMps], [2.0, 4.0]);
  });

  test('returns an empty list for an unknown race', () async {
    expect(await reader('nincs-ilyen', null), isEmpty);
  });
}
