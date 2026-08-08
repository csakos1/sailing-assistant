import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SnapshotLoggerImpl logger;
  late TrackSampleReaderImpl reader;

  // A snapshot a valódi `RaceSnapshot.toJson` alakban kerül a sorba, ezért
  // a teszt a tényleges JSON-szerkezeten igazolja a json_extract útvonalait,
  // nem egy kézzel összerakott stringen.
  RaceSnapshot snapshotAt(
    DateTime t, {
    Coordinate? position,
    double? sogMps,
  }) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(
      lastUpdate: t,
      position: position,
      speedOverGround: sogMps == null ? null : Speed(metersPerSecond: sogMps),
    ),
    connectionStatus: const Connected(),
    tickTime: t,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(db);
    reader = TrackSampleReaderImpl(db);
    // A snapshot_logs.raceId idegen kulcsa miatt kell egy race-sor.
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-1',
            name: 'Teszt',
            statusIndex: RaceStatus.notStarted,
            createdAt: DateTime(2026, 5, 1, 10),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('a tárolt JSON-ból kiolvassa a sebességet és a pozíciót', () async {
    // ARRANGE
    await logger.log(
      'race-1',
      snapshotAt(
        DateTime.utc(2026, 5, 1, 10, 0, 1),
        position: const Coordinate(latitude: 46.9, longitude: 18.05),
        sogMps: 4.5,
      ),
    );

    // ACT
    final samples = await reader('race-1');

    // ASSERT — a három mennyiség a beágyazott boatState-ből jön.
    final sample = samples.single;
    expect(sample.sogMps, 4.5);
    expect(sample.latDeg, closeTo(46.9, 1e-9));
    expect(sample.lonDeg, closeTo(18.05, 1e-9));
  });

  test('hiányzó pozíciónál és sebességnél null-t ad', () async {
    // ARRANGE — a boatState mindkét mezője null, tehát a JSON-ban is null
    // áll; a json_extract NULL-t ad vissza.
    await logger.log('race-1', snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 1)));

    // ACT
    final samples = await reader('race-1');

    // ASSERT
    final sample = samples.single;
    expect(sample.sogMps, isNull);
    expect(sample.latDeg, isNull);
    expect(sample.lonDeg, isNull);
  });

  test('a mintákat időrendben adja vissza', () async {
    // ARRANGE — fordított sorrendben írjuk be őket.
    await logger.log(
      'race-1',
      snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 3), sogMps: 7.5),
    );
    await logger.log(
      'race-1',
      snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 1), sogMps: 2.5),
    );

    // ACT
    final samples = await reader('race-1');

    // ASSERT — a rendezés a helyesség része: az úthossz szomszédos
    // pozíciókat láncol.
    expect([for (final s in samples) s.sogMps], [2.5, 7.5]);
  });

  test('csak a kért verseny mintáit adja vissza', () async {
    // ARRANGE — két verseny, mindkettőnek egy-egy mintája.
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-2',
            name: 'Masik',
            statusIndex: RaceStatus.notStarted,
            createdAt: DateTime(2026, 5, 2, 10),
          ),
        );
    await logger.log(
      'race-1',
      snapshotAt(DateTime.utc(2026, 5, 1, 10, 0, 1), sogMps: 1.5),
    );
    await logger.log(
      'race-2',
      snapshotAt(DateTime.utc(2026, 5, 2, 10, 0, 1), sogMps: 9.5),
    );

    // ACT
    final samples = await reader('race-1');

    // ASSERT
    expect([for (final s in samples) s.sogMps], [1.5]);
  });

  test('ismeretlen versenyre üres listát ad', () async {
    // ACT
    final samples = await reader('nincs-ilyen');

    // ASSERT
    expect(samples, isEmpty);
  });
}
