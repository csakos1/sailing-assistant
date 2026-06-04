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
  late StreamController<DateTime> tick;
  late RaceEngine engine;
  late List<RaceSnapshot> snapshots;

  setUp(() {
    source = _FakeNmeaSource();
    logger = _FakeTelemetryLogger();
    tick = StreamController<DateTime>();
    engine = RaceEngine(
      nmeaStream: source,
      telemetryLogger: logger,
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
