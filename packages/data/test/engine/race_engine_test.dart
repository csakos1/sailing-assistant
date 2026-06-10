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
  ConnectionStatus get currentStatus => const Disconnected();

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
