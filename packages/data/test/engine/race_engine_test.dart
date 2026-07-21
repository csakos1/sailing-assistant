import 'dart:async';
import 'dart:math' show pi;

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Közös fixtúrák.
  final fixedNow = DateTime.utc(2025, 6, 1, 10, 0, 5);
  final eventTime = DateTime.utc(2025, 6, 1, 10);
  final tickTime = DateTime.utc(2025, 6, 1, 10, 0, 1);
  const boatPosition = Coordinate(latitude: 46.9, longitude: 18.05);
  const markPosition = Coordinate(latitude: 46.95, longitude: 18.1);
  final race = Race.create(
    id: 'r1',
    name: 'Teszt',
    marks: const [Mark(sequence: 1, name: 'Bóya 1', position: markPosition)],
  );

  late _FakeNmeaSource source;
  late _FakeTelemetryLogger logger;
  late _FakeSnapshotLogger snapshotLogger;
  late StreamController<DateTime> tick;
  late RaceEngine engine;
  late List<RaceSnapshot> snapshots;

  setUp(() {
    source = _FakeNmeaSource();
    logger = _FakeTelemetryLogger();
    snapshotLogger = _FakeSnapshotLogger();
    tick = StreamController<DateTime>();
    engine = RaceEngine(
      nmeaStream: source,
      telemetryLogger: logger,
      snapshotLogger: snapshotLogger,
      tickSource: tick.stream,
      now: () => fixedNow,
    );
    snapshots = [];
    engine.snapshots.listen(snapshots.add);
  });

  tearDown(() async {
    await engine.dispose();
    await source.close();
    await tick.close();
  });

  group('sekély-víz riasztás (ADR 0031 D4)', () {
    setUp(() {
      // Az állapotgép isConnected-je ebből jön; disconnecten resetel.
      source.status = const Connected();
    });

    DateTime tickAt(int seconds) => tickTime.add(Duration(seconds: seconds));

    // A mélység előbb a BoatState-be foldolódik, az állapotgép csak a
    // rákövetkező tickben lép, ezért esemény és tick párban megy.
    Future<void> feedDepth(double meters, DateTime at) async {
      source.emitEvent(DepthEvent(Depth(meters: meters), eventTime));
      await pumpEventQueue();
      tick.add(at);
      await pumpEventQueue();
    }

    test('mélység nélkül nincs riasztás', () async {
      // ARRANGE
      await engine.start(race);

      // ACT
      tick.add(tickAt(0));
      await pumpEventQueue();

      // ASSERT
      expect(snapshots.single.depthAlertMeters, isNull);
      expect(snapshots.single.depthBuzzCounter, 0);
    });

    test('a küszöb felett nincs riasztás', () async {
      await engine.start(race);

      await feedDepth(2.6, tickAt(0));

      expect(snapshots.last.depthAlertMeters, isNull);
      expect(snapshots.last.depthBuzzCounter, 0);
    });

    test('belépés, új mélypont, ratchet, majd feloldás', () async {
      // ARRANGE
      await engine.start(race);

      // ACT & ASSERT: belépés a 2,5 m-es küszöb alatt.
      await feedDepth(2.4, tickAt(0));
      expect(snapshots.last.depthAlertMeters, closeTo(2.4, 1e-9));
      expect(snapshots.last.depthBuzzCounter, 1);

      // Új mélypont (sekélyebb vödör): új rezgés.
      await feedDepth(2.2, tickAt(1));
      expect(snapshots.last.depthAlertMeters, closeTo(2.2, 1e-9));
      expect(snapshots.last.depthBuzzCounter, 2);

      // Kicsit mélyebb, de még a küszöb alatt: NINCS új rezgés
      // (ratchet). A riasztás aktív marad, a számláló nem lép.
      await feedDepth(2.3, tickAt(2));
      expect(snapshots.last.depthAlertMeters, closeTo(2.3, 1e-9));
      expect(snapshots.last.depthBuzzCounter, 2);

      // 3,0 m felett: az epizód lezárul, a számláló megmarad.
      await feedDepth(3.1, tickAt(3));
      expect(snapshots.last.depthAlertMeters, isNull);
      expect(snapshots.last.depthBuzzCounter, 2);
    });

    test('disconnect alatt reset, de a számláló megmarad', () async {
      // ARRANGE: aktív epizód.
      await engine.start(race);
      await feedDepth(2.4, tickAt(0));
      expect(snapshots.last.depthBuzzCounter, 1);

      // ACT: megszakad a kapcsolat (élő feed nélkül a mélység stale).
      source.status = const Disconnected();
      tick.add(tickAt(1));
      await pumpEventQueue();

      // ASSERT: nincs aktív riasztás, de a számláló nem esik vissza
      // (különben az óra újra rezegne visszacsatlakozáskor).
      expect(snapshots.last.depthAlertMeters, isNull);
      expect(snapshots.last.depthBuzzCounter, 1);
    });
  });

  group('polár cél-sebesség (ADR 0028 Add. 3)', () {
    // Egyszerű polár: a TWA=30° sor minden TWS-oszlopban 5.0 kn, így a
    // konverzió pontossága nem számít; a TWA=0° sor no-go (üres).
    final polar = Polar(
      twaAxis: const [0, 30, 60],
      twsAxis: const [4, 6],
      grid: const [
        [null, null],
        [5.0, 5.0],
        [4.5, 5.6],
      ],
    );

    WindData windAt(double twaDegrees) => WindData(
      apparentAngle: Angle(degrees: twaDegrees),
      apparentSpeed: const Speed(metersPerSecond: 6),
      timestamp: eventTime,
      trueAngleWater: Angle(degrees: twaDegrees),
      trueSpeedWater: const Speed(metersPerSecond: 3),
    );

    test('polár + szél, de nem-live TWD → vmgSteerCorrection null', () async {
      // ARRANGE — van polár + water-szél (a target VMG kiszámolható),
      // de a hajó nem mozog (nincs COG/SOG) → a TWD-minőség nem `live`.
      await engine.start(race, polar: polar);
      source.emitEvent(WindEvent(windAt(30)));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT — a target VMG megvan, de a forduló-elnyomás (F7)
      // null-ozza a steer-korrekciót.
      expect(snapshots.single.targetVmgKnots, isNotNull);
      expect(snapshots.single.vmgSteerCorrection, isNull);
    });

    test('polár + szél → a snapshot a polár-cellát adja', () async {
      // ARRANGE — TWA 30° (axis-pont), TWS 3 m/s (≈ 5.83 kn, [4,6]).
      await engine.start(race, polar: polar);
      source.emitEvent(WindEvent(windAt(30)));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT — a TWA=30 sor minden oszlopa 5.0.
      expect(snapshots.single.targetSpeedKnots, closeTo(5, 1e-9));
    });

    test('polár nélkül a cél-sebesség null', () async {
      // ARRANGE — start polár nélkül, de van szél.
      await engine.start(race);
      source.emitEvent(WindEvent(windAt(30)));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT
      expect(snapshots.single.targetSpeedKnots, isNull);
    });

    test('no-go (TWA < 25°) alatt a cél-sebesség null', () async {
      // ARRANGE — TWA 10°, a no-go küszöb (25°) alatt.
      await engine.start(race, polar: polar);
      source.emitEvent(WindEvent(windAt(10)));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT
      expect(snapshots.single.targetSpeedKnots, isNull);
    });
  });

  test(
    'minden tick a snapshot-loggernek adja a snapshotot a raceId-vel',
    () async {
      // ARRANGE — aktív race + pozíció, hogy a tick snapshotot adjon.
      await engine.start(race);
      source.emitEvent(PositionEvent(boatPosition, eventTime));
      await pumpEventQueue();

      // ACT — két tick.
      tick.add(tickTime);
      await pumpEventQueue();
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT — mindkét snapshot a loggerhez ért, a race id-jával; a
      // logolt snapshot UGYANAZ a példány, mint az emittált.
      expect(snapshotLogger.entries, hasLength(2));
      expect(snapshotLogger.entries.first.raceId, race.id);
      expect(
        snapshotLogger.entries.first.snapshot,
        same(snapshots.first),
      );
    },
  );

  test('start csatlakozik a forráshoz', () async {
    await engine.start(race);
    expect(source.connectCalled, isTrue);
  });

  test('a tick a foldolt állapotból prediction-snapshotot emittál', () async {
    await engine.start(race);
    source.emitEvent(PositionEvent(boatPosition, eventTime));
    await pumpEventQueue();

    tick.add(tickTime);
    await pumpEventQueue();

    expect(snapshots, hasLength(1));
    final snap = snapshots.single;
    expect(snap.eventCount, 1);
    expect(snap.boatState.position, boatPosition);
    expect(snap.tickTime, tickTime);
    expect(snap.raceStatus, RaceStatus.notStarted);
    // Aktív bója + pozíció van → a prediction nem null, az aktív bójára szól.
    expect(snap.prediction?.mark, race.marks.first);
    expect(snap.prediction?.distanceToMark, isNotNull);
  });

  test(
    'snapshot csak tickre keletkezik; az eventCount a foldolt eseményeké',
    () async {
      await engine.start(race);
      source
        ..emitEvent(PositionEvent(boatPosition, eventTime))
        ..emitEvent(SpeedEvent(const Speed(metersPerSecond: 3), eventTime));
      await pumpEventQueue();

      expect(snapshots, isEmpty); // tick nélkül nincs snapshot

      tick.add(tickTime);
      await pumpEventQueue();

      expect(snapshots.single.eventCount, 2);
    },
  );

  test(
    'a nyers sorokat telemetriaként logolja, az üreseket kihagyja',
    () async {
      await engine.start(race);
      source
        ..emitRaw('sentence-1')
        ..emitRaw('') // üres → skip
        ..emitRaw('sentence-2');
      await pumpEventQueue();

      expect(logger.records, hasLength(2));
      expect(logger.records.first.raceId, 'r1');
      expect(logger.records.first.rawSentence, 'sentence-1');
    },
  );

  test('dispose lekapcsolja a forrást és lezárja a loggert', () async {
    await engine.start(race);
    await engine.dispose();

    expect(source.disconnectCalled, isTrue);
    expect(logger.disposed, isTrue);
  });

  group('mark-rounding', () {
    const metersPerDegLat = 6371000 * pi / 180;
    const mark1 = Mark(
      sequence: 1,
      name: 'Bóya 1',
      position: Coordinate(latitude: 46.9, longitude: 18),
    );
    const mark2 = Mark(
      sequence: 2,
      name: 'Bóya 2',
      position: Coordinate(latitude: 46.8, longitude: 17.9),
    );
    final activeRace = Race.create(
      id: 'rr',
      name: 'Rounding',
      marks: const [mark1, mark2],
    ).start(at: eventTime);

    // A mark1-től északra `metersNorth` méterre lévő pozíció (meridián
    // mentén a Haversine pontosan R·Δlat).
    Coordinate boatNorthOfMark1(double metersNorth) => Coordinate(
      latitude: mark1.position.latitude + metersNorth / metersPerDegLat,
      longitude: mark1.position.longitude,
    );

    Future<void> emitAtThenTick(double metersNorth, DateTime at) async {
      source.emitEvent(PositionEvent(boatNorthOfMark1(metersNorth), eventTime));
      await pumpEventQueue();
      tick.add(at);
      await pumpEventQueue();
    }

    test('a hajó körözi a bóját, a következő bójára lép', () async {
      // ARRANGE
      await engine.start(activeRace);

      // ACT — közelít a küszöbön belülre, majd a hiszterézist meghaladva
      // távolodik.
      await emitAtThenTick(40, tickTime);
      await emitAtThenTick(10, tickTime.add(const Duration(seconds: 1)));
      await emitAtThenTick(20, tickTime.add(const Duration(seconds: 2)));

      // ASSERT — az első két tick az 1. bóját célozza, a harmadik a 2.-at.
      expect(snapshots[0].prediction?.mark, mark1);
      expect(snapshots[1].prediction?.mark, mark1);
      expect(snapshots[2].prediction?.mark, mark2);
    });

    test('notStarted race alatt nem lép', () async {
      // ARRANGE — notStarted, ugyanazok a bóják.
      final notStarted = Race.create(
        id: 'rr',
        name: 'Rounding',
        marks: const [mark1, mark2],
      );
      await engine.start(notStarted);

      // ACT — ugyanaz a közelít-távolodik profil.
      await emitAtThenTick(40, tickTime);
      await emitAtThenTick(10, tickTime.add(const Duration(seconds: 1)));
      await emitAtThenTick(20, tickTime.add(const Duration(seconds: 2)));

      // ASSERT — végig az 1. bóját célozza (notStarted, marks[0]).
      expect(snapshots.last.prediction?.mark, mark1);
    });
  });

  group('parancs-protokoll (start/finish)', () {
    const metersPerDegLat = 6371000 * pi / 180;
    const mark1 = Mark(
      sequence: 1,
      name: 'Bóya 1',
      position: Coordinate(latitude: 46.9, longitude: 18),
    );
    const mark2 = Mark(
      sequence: 2,
      name: 'Bóya 2',
      position: Coordinate(latitude: 46.8, longitude: 17.9),
    );
    final notStartedRace = Race.create(
      id: 'cmd',
      name: 'Parancs',
      marks: const [mark1, mark2],
    );

    Coordinate boatNorthOfMark1(double metersNorth) => Coordinate(
      latitude: mark1.position.latitude + metersNorth / metersPerDegLat,
      longitude: mark1.position.longitude,
    );

    Future<void> emitAtThenTick(double metersNorth, DateTime at) async {
      source.emitEvent(PositionEvent(boatNorthOfMark1(metersNorth), eventTime));
      await pumpEventQueue();
      tick.add(at);
      await pumpEventQueue();
    }

    test('applyStartCommand active-ra vált → a mark-rounding lép', () async {
      // ARRANGE — notStarted race; a parancs előtt nincs léptetés.
      await engine.start(notStartedRace);

      // ACT — start parancs, majd közelít a küszöbön belülre és távolodik.
      engine.applyStartCommand(eventTime);
      await emitAtThenTick(40, tickTime);
      await emitAtThenTick(10, tickTime.add(const Duration(seconds: 1)));
      await emitAtThenTick(20, tickTime.add(const Duration(seconds: 2)));

      // ASSERT — a parancs után active, így a 3. tick a 2. bójára lép.
      expect(snapshots[0].prediction?.mark, mark1);
      expect(snapshots[2].prediction?.mark, mark2);
    });

    test('applyStartCommand no-op, ha már active (nem dob)', () async {
      // ARRANGE — már active race.
      await engine.start(notStartedRace.start(at: eventTime));

      // ACT & ASSERT — a guard miatt a Race.start assertje nem fut le.
      expect(() => engine.applyStartCommand(eventTime), returnsNormally);
    });

    test('applyFinishCommand a predikciót null-ra viszi', () async {
      // ARRANGE — active race, egy tick még az 1. bóját célozza.
      await engine.start(notStartedRace.start(at: eventTime));
      await emitAtThenTick(40, tickTime);
      expect(snapshots.last.prediction?.mark, mark1);

      // ACT — finish parancs, majd egy tick.
      engine.applyFinishCommand(tickTime.add(const Duration(seconds: 1)));
      await emitAtThenTick(40, tickTime.add(const Duration(seconds: 2)));

      // ASSERT — finished → nincs aktív bója → nincs prediction.
      expect(snapshots.last.prediction, isNull);
    });

    test('applyFinishCommand no-op, ha nem active (notStarted)', () async {
      // ARRANGE — notStarted race.
      await engine.start(notStartedRace);

      // ACT — finish parancs notStartedre (guard), majd egy tick.
      engine.applyFinishCommand(eventTime);
      await emitAtThenTick(40, tickTime);

      // ASSERT — a finish nem futott le, az 1. bóját célozza.
      expect(snapshots.last.prediction?.mark, mark1);
    });
  });

  group('parancs-protokoll (roundMark)', () {
    const metersPerDegLat = 6371000 * pi / 180;
    const mark1 = Mark(
      sequence: 1,
      name: 'Bóya 1',
      position: Coordinate(latitude: 46.9, longitude: 18),
    );
    const mark2 = Mark(
      sequence: 2,
      name: 'Bóya 2',
      position: Coordinate(latitude: 46.8, longitude: 17.9),
    );
    final notStartedRace = Race.create(
      id: 'rm',
      name: 'RoundMark',
      marks: const [mark1, mark2],
    );

    Coordinate boatNorthOf(Mark mark, double metersNorth) => Coordinate(
      latitude: mark.position.latitude + metersNorth / metersPerDegLat,
      longitude: mark.position.longitude,
    );

    Future<void> emitNorthOfThenTick(
      Mark mark,
      double metersNorth,
      DateTime at,
    ) async {
      source.emitEvent(
        PositionEvent(boatNorthOf(mark, metersNorth), eventTime),
      );
      await pumpEventQueue();
      tick.add(at);
      await pumpEventQueue();
    }

    test('active-ban a következő bójára lép', () async {
      // ARRANGE — active race; 200 m-en a detektor magától nem lépne.
      await engine.start(notStartedRace.start(at: eventTime));
      await emitNorthOfThenTick(mark1, 200, tickTime);
      expect(snapshots.last.prediction?.mark, mark1);

      // ACT — kézi bója-megkerülés parancs, majd egy tick.
      engine.applyRoundMarkCommand();
      await emitNorthOfThenTick(
        mark1,
        200,
        tickTime.add(const Duration(seconds: 1)),
      );

      // ASSERT — a parancs léptetett: a 2. bóját célozza.
      expect(snapshots.last.prediction?.mark, mark2);
    });

    test('léptet, majd a 2. bóját auto-körözi (reset)', () async {
      // ARRANGE — active race; az 1. bóját kézzel körözzük → 2. bója.
      await engine.start(notStartedRace.start(at: eventTime));
      engine.applyRoundMarkCommand();

      // ACT — a 2. bója köré közelít-távolodik. A reset után a detektor
      // tiszta lapról a 2. bóját követi; reset nélkül a régi closest-approach
      // állapot meghamisítaná a körözést.
      await emitNorthOfThenTick(mark2, 40, tickTime);
      await emitNorthOfThenTick(
        mark2,
        10,
        tickTime.add(const Duration(seconds: 1)),
      );
      await emitNorthOfThenTick(
        mark2,
        20,
        tickTime.add(const Duration(seconds: 2)),
      );

      // ASSERT — a 2. (utolsó) bóját az auto-detektor körözte → finished.
      expect(snapshots.last.prediction, isNull);
    });

    test('no-op, ha nem active (notStarted) — nem dob, nem lép', () async {
      // ARRANGE — notStarted race.
      await engine.start(notStartedRace);

      // ACT & ASSERT — a guard miatt a Race.roundCurrentMark assertje nem fut.
      expect(engine.applyRoundMarkCommand, returnsNormally);
      await emitNorthOfThenTick(mark1, 200, tickTime);
      expect(snapshots.last.prediction?.mark, mark1);
    });
  });

  group('TWD-minőség a snapshotban (ADR 0020 D7)', () {
    test('live: COG+SOG mozgásban + bow TWA → twdQuality live', () async {
      // ARRANGE — előbb a COG/SOG (a derive a _boatState-ből veszi), majd
      // a szél; a derive a WindEvent ágában fut.
      await engine.start(race);
      const cog = Bearing.true_(95);
      final wind = WindData(
        apparentAngle: const Angle(degrees: 30),
        apparentSpeed: const Speed(metersPerSecond: 6),
        timestamp: eventTime,
        trueAngleWater: const Angle(degrees: 40), // csúcs-relatív TWA
      );
      source
        ..emitEvent(
          CogSogEvent(cog, const Speed(metersPerSecond: 3), eventTime),
        )
        ..emitEvent(WindEvent(wind));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT — SOG 3 m/s (> 1.5 kn) → COG-kapu nyit, friss bow TWA → live.
      expect(snapshots.single.twdQuality, TwdQuality.live);
    });

    test('live TWD + polár → a steer-korrekció előáll (F7 happy)', () async {
      // ARRANGE — live TWD (mozgó hajó) + betöltött polár + water-szél
      // (TWA 40°, TWS 3 m/s) → a kapu nyit, a target VMG kiszámolható.
      final polar = Polar(
        twaAxis: const [0, 30, 60, 90],
        twsAxis: const [4, 6],
        grid: const [
          [null, null],
          [5.0, 5.0],
          [4.5, 5.6],
          [4.0, 5.0],
        ],
      );
      const cog = Bearing.true_(95);
      final wind = WindData(
        apparentAngle: const Angle(degrees: 35),
        apparentSpeed: const Speed(metersPerSecond: 6),
        timestamp: eventTime,
        trueAngleWater: const Angle(degrees: 40),
        trueSpeedWater: const Speed(metersPerSecond: 3),
      );
      await engine.start(race, polar: polar);
      source
        ..emitEvent(
          CogSogEvent(cog, const Speed(metersPerSecond: 3), eventTime),
        )
        ..emitEvent(WindEvent(wind));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT — live TWD + kiszámolható optimum → a steer Angle.
      expect(snapshots.single.twdQuality, TwdQuality.live);
      expect(snapshots.single.vmgSteerCorrection, isA<Angle>());
    });
    test('unavailable: csak pozíció, nincs szél → default marad', () async {
      // ARRANGE — WindEvent nélkül a derive sosem fut → marad a default.
      await engine.start(race);
      source.emitEvent(PositionEvent(boatPosition, eventTime));
      await pumpEventQueue();

      // ACT
      tick.add(tickTime);
      await pumpEventQueue();

      // ASSERT
      expect(snapshots.single.twdQuality, TwdQuality.unavailable);
    });
  });
}

// Vezérelhető fake NMEA-forrás, ami nyers sorokat is ad (RawNmeaLineSource).
class _FakeNmeaSource implements NmeaStream, RawNmeaLineSource {
  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();
  final StreamController<String> _raw = StreamController<String>.broadcast();
  final StreamController<ConnectionStatus> _status =
      StreamController<ConnectionStatus>.broadcast();

  bool connectCalled = false;
  bool disconnectCalled = false;
  // A tesztek állíthatják: az engine ebből vezeti le az isConnected-et
  // (pl. a sekély-víz állapotgéphez, ADR 0031 D4).
  ConnectionStatus status = const Disconnected();

  void emitEvent(DomainEvent event) => _events.add(event);
  void emitRaw(String line) => _raw.add(line);

  Future<void> close() async {
    await _events.close();
    await _raw.close();
    await _status.close();
  }

  @override
  Stream<DomainEvent> get events => _events.stream;

  @override
  Stream<String> get rawLines => _raw.stream;

  @override
  Stream<ConnectionStatus> get statusChanges => _status.stream;

  @override
  ConnectionStatus get currentStatus => status;

  @override
  Future<void> connect() async => connectCalled = true;

  @override
  Future<void> disconnect() async => disconnectCalled = true;
}

// Fake telemetria-logger, ami csak gyűjti a rekordokat.
class _FakeTelemetryLogger implements TelemetryLogger {
  final List<TelemetryRecord> records = [];
  bool disposed = false;

  @override
  Future<void> log(TelemetryRecord record) async => records.add(record);

  @override
  Future<void> dispose() async => disposed = true;
}

// Fake snapshot-logger: a (raceId, snapshot) párokat rögzíti.
class _FakeSnapshotLogger implements SnapshotLogger {
  final List<({String raceId, RaceSnapshot snapshot})> entries = [];
  bool disposed = false;

  @override
  Future<void> log(String raceId, RaceSnapshot snapshot) async =>
      entries.add((raceId: raceId, snapshot: snapshot));

  @override
  Future<void> dispose() async => disposed = true;
}
