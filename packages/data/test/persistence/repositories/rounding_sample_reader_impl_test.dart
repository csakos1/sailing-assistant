import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SnapshotLoggerImpl logger;
  late RoundingSampleReaderImpl reader;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(database);
    reader = RoundingSampleReaderImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  // Szülő race-sor: az FK-cascade (snapshot_logs.raceId -> races.id) miatt
  // a snapshot-íráshoz előbb léteznie kell a versenynek.
  Future<void> insertRace(String id) {
    return database
        .into(database.races)
        .insert(
          RacesCompanion.insert(
            id: id,
            name: 'Test $id',
            statusIndex: RaceStatus.finished,
            createdAt: DateTime.utc(2026, 6, 6),
          ),
        );
  }

  // Egy realisztikus RaceSnapshot a mapping-ellenorzeshez; az iro-oldal
  // (SnapshotLoggerImpl) ezt a valodi toJson-on at perzisztalja.
  RaceSnapshot snapshot({
    required DateTime tick,
    String? markName,
    double? predictedTwaDeg,
    double? bandDeg,
    String confidence = 'high',
    double? trueTwaDeg,
    double? cogDeg,
    double? sogMps,
    Coordinate? position,
    double bearingDeg = 90,
    RaceStatus raceStatus = RaceStatus.active,
    TwdQuality twdQuality = TwdQuality.live,
  }) {
    return RaceSnapshot(
      eventCount: 1,
      boatState: BoatState(
        lastUpdate: tick,
        position: position,
        courseOverGround: cogDeg == null
            ? null
            : Bearing(degrees: cogDeg, reference: BearingReference.trueNorth),
        speedOverGround: sogMps == null ? null : Speed(metersPerSecond: sogMps),
      ),
      connectionStatus: const Connected(),
      tickTime: tick,
      raceStatus: raceStatus,
      twdQuality: twdQuality,
      wind: trueTwaDeg == null
          ? null
          : WindData(
              apparentAngle: const Angle(degrees: 30),
              apparentSpeed: const Speed(metersPerSecond: 5),
              timestamp: tick,
              trueAngleWater: Angle(degrees: trueTwaDeg),
            ),
      prediction: markName == null
          ? null
          : MarkPrediction(
              mark: Mark(
                sequence: 1,
                name: markName,
                position: const Coordinate(latitude: 46.9, longitude: 18),
              ),
              bearingToMark: Bearing(
                degrees: bearingDeg,
                reference: BearingReference.trueNorth,
              ),
              distanceToMark: const Distance(meters: 500),
              etaSource: EtaSource.sog,
              shiftConfidence: WindShiftConfidence.values.byName(confidence),
              calculatedAt: tick,
              eta: const Duration(minutes: 5),
              predictedTwaAtMark: predictedTwaDeg == null
                  ? null
                  : Angle(degrees: predictedTwaDeg),
              forecastBandDegrees: bandDeg,
            ),
    );
  }

  final base = DateTime.utc(2026, 6, 6, 11);
  final later = base.add(const Duration(seconds: 1));

  group('RoundingSampleReaderImpl', () {
    test('a race pillanatkepeit idorendben, mappelve adja vissza', () async {
      // ARRANGE — a kesobbi tick-et irjuk be ELOSZOR (a rendezest teszteli).
      await insertRace('race-1');
      await logger.log(
        'race-1',
        snapshot(
          tick: later,
          markName: 'A',
          predictedTwaDeg: -120,
          bandDeg: 5,
          trueTwaDeg: -117,
          cogDeg: 90,
          sogMps: 3.2,
          position: const Coordinate(latitude: 46.9, longitude: 18),
        ),
      );
      await logger.log(
        'race-1',
        snapshot(tick: base, markName: 'A', predictedTwaDeg: -119),
      );

      // ACT
      final samples = await reader('race-1');

      // ASSERT — idorend: a base elobb, mint a later (timestamp ASC).
      expect(samples, hasLength(2));
      expect(samples.first.tickTime.isAtSameMomentAs(base), isTrue);
      expect(samples.last.tickTime.isAtSameMomentAs(later), isTrue);
      expect(
        samples.map((s) => s.predictedTwaAtMarkDeg),
        [-119, -120],
      );
      // A teljes mezo-mapping a later (mindent kitolto) pillanatkepen.
      final last = samples.last;
      expect(last.raceStatus, 'active');
      expect(last.twdQuality, 'live');
      expect(last.markName, 'A');
      expect(last.predictedTwaAtMarkDeg, -120);
      expect(last.shiftConfidence, 'high');
      expect(last.forecastBandDeg, 5);
      expect(last.bearingToMarkDeg, 90);
      expect(last.currentTwaDeg, -117);
      expect(last.sogMps, 3.2);
      expect(last.cogDeg, 90);
      expect(last.latDeg, 46.9);
      expect(last.lonDeg, 18);
    });

    test('csak az adott race sorait adja (raceId-szures)', () async {
      // ARRANGE
      await insertRace('race-1');
      await insertRace('race-2');
      await logger.log('race-1', snapshot(tick: base, markName: 'A'));
      await logger.log('race-2', snapshot(tick: base, markName: 'B'));

      // ACT
      final samples = await reader('race-1');

      // ASSERT
      expect(samples, hasLength(1));
      expect(samples.single.markName, 'A');
    });

    test('prediction nelkul a mark/predikcio-mezok null', () async {
      // ARRANGE — nincs aktiv boja -> nincs prediction; a wind viszont megvan.
      await insertRace('race-1');
      await logger.log('race-1', snapshot(tick: base, trueTwaDeg: -100));

      // ACT
      final samples = await reader('race-1');

      // ASSERT
      final sample = samples.single;
      expect(sample.markName, isNull);
      expect(sample.predictedTwaAtMarkDeg, isNull);
      expect(sample.forecastBandDeg, isNull);
      expect(sample.bearingToMarkDeg, isNull);
      expect(sample.currentTwaDeg, -100);
      expect(sample.latDeg, isNull);
      expect(sample.lonDeg, isNull);
    });

    test('ismeretlen race-re ures lista', () async {
      // ACT
      final samples = await reader('nincs-ilyen');

      // ASSERT
      expect(samples, isEmpty);
    });
  });
}
