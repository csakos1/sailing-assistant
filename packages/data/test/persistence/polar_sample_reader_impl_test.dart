import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SnapshotLoggerImpl logger;
  late PolarSampleReaderImpl reader;

  // A snapshot a valodi RaceSnapshot.toJson alakban kerul a sorba, igy a
  // teszt a tenyleges JSON-szerkezeten igazolja a json_extract utvonalait.
  RaceSnapshot snapshotAt(
    DateTime t, {
    double? twaDeg,
    double? twsMps,
    double? stwMps,
    bool hasWind = true,
  }) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(
      lastUpdate: t,
      speedThroughWater: stwMps == null ? null : Speed(metersPerSecond: stwMps),
    ),
    connectionStatus: const Connected(),
    tickTime: t,
    wind: hasWind
        ? WindData(
            apparentAngle: const Angle(degrees: 30),
            apparentSpeed: const Speed(metersPerSecond: 6),
            timestamp: t,
            trueAngleWater: twaDeg == null ? null : Angle(degrees: twaDeg),
            trueSpeedWater: twsMps == null
                ? null
                : Speed(metersPerSecond: twsMps),
          )
        : null,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(db);
    reader = PolarSampleReaderImpl(db);
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

  test('reads wind angle, wind speed, water speed and time', () async {
    // ARRANGE
    await logger.log(
      'race-1',
      snapshotAt(
        DateTime.utc(2026, 5, 1, 10, 0, 1),
        twaDeg: -42.5,
        twsMps: 5.5,
        stwMps: 3.25,
      ),
    );

    // ACT
    final sample = (await reader('race-1', null)).single;

    // ASSERT
    expect(
      sample,
      PolarSample(
        timestamp: DateTime.utc(2026, 5, 1, 10, 0, 1),
        twaDeg: -42.5,
        twsMps: 5.5,
        stwMps: 3.25,
      ),
    );
    expect(sample.durationSeconds, 1);
  });

  test('returns nulls for a snapshot without wind or water speed', () async {
    // ARRANGE
    await logger.log(
      'race-1',
      snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 1), hasWind: false),
    );

    // ACT
    final sample = (await reader('race-1', null)).single;

    // ASSERT
    expect(sample.twaDeg, isNull);
    expect(sample.twsMps, isNull);
    expect(sample.stwMps, isNull);
  });

  test('filters by the window, bounds included, in time order', () async {
    // ARRANGE - forditott sorrendben irjuk be oket.
    for (final second in [5, 4, 2, 1]) {
      await logger.log(
        'race-1',
        snapshotAt(
          DateTime.utc(2026, 5, 1, 10, 0, second),
          stwMps: second.toDouble(),
        ),
      );
    }
    final window = TimeWindow(
      start: DateTime.utc(2026, 5, 1, 10, 0, 2),
      end: DateTime.utc(2026, 5, 1, 10, 0, 4),
    );

    // ACT
    final samples = await reader('race-1', window);

    // ASSERT
    expect([for (final s in samples) s.stwMps], [2.0, 4.0]);
  });

  test('returns an empty list for an unknown race', () async {
    expect(await reader('nincs-ilyen', null), isEmpty);
  });
}
