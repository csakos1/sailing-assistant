import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/app_database_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';
import 'package:phone/providers/telemetry_logger_provider.dart';

class _FakeNmeaStream implements NmeaStream {
  @override
  Stream<DomainEvent> get events => const Stream<DomainEvent>.empty();

  @override
  Stream<ConnectionStatus> get statusChanges =>
      const Stream<ConnectionStatus>.empty();

  @override
  ConnectionStatus get currentStatus => const Disconnected();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}

class _FakeRawNmeaStream extends _FakeNmeaStream implements RawNmeaLineSource {
  final StreamController<String> _rawLines =
      StreamController<String>.broadcast();

  void pushLine(String line) => _rawLines.add(line);

  Future<void> dispose() => _rawLines.close();

  @override
  Stream<String> get rawLines => _rawLines.stream;
}

void main() {
  late AppDatabase db;
  late _FakeRawNmeaStream rawSource;
  late ProviderContainer container;
  final fixedNow = DateTime(2025, 6, 1, 12);

  const markA = Mark(
    sequence: 1,
    name: '1. bója',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  final race = Race.create(id: 'race-1', name: 'Teszt', marks: const [markA]);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    rawSource = _FakeRawNmeaStream();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nmeaStreamProvider.overrideWithValue(rawSource),
        clockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(rawSource.dispose);
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  ActiveRaceNotifier activeRace() =>
      container.read(activeRaceProvider.notifier);

  Future<List<TelemetryRow>> telemetryRows() =>
      db.select(db.telemetryRecords).get();

  test('aktív race alatt a nyers sorok telemetriaként mentődnek', () async {
    // ARRANGE — a logger-providert életben tartjuk, és indítjuk a race-t.
    final sub = container.listen(telemetryLoggerProvider, (_, _) {});
    addTearDown(sub.close);
    activeRace().activeRace = race;
    await activeRace().start();
    await pumpEventQueue();

    // ACT — sorok érkeznek, majd deaktiválás → a teardown záró flush-a ír.
    rawSource
      ..pushLine(r'$GPRMC,1*00')
      ..pushLine(r'$IIMWV,2*00');
    await pumpEventQueue();
    activeRace().activeRace = null;
    await pumpEventQueue();

    // ASSERT
    final rows = await telemetryRows();
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.rawSentence), [r'$GPRMC,1*00', r'$IIMWV,2*00']);
    expect(rows.every((r) => r.raceId == 'race-1'), isTrue);
    expect(rows.every((r) => r.timestamp == fixedNow), isTrue);
  });

  test('notStarted race alatt NEM logol', () async {
    final sub = container.listen(telemetryLoggerProvider, (_, _) {});
    addTearDown(sub.close);
    // Csak kiválasztjuk (notStarted), nem indítjuk.
    activeRace().activeRace = race;
    await pumpEventQueue();

    rawSource.pushLine(r'$GPRMC,1*00');
    await pumpEventQueue();
    activeRace().activeRace = null;
    await pumpEventQueue();

    expect(await telemetryRows(), isEmpty);
  });

  test('nem RawNmeaLineSource forrásnál no-op', () async {
    final plainContainer = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nmeaStreamProvider.overrideWithValue(_FakeNmeaStream()),
        clockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(plainContainer.dispose);
    final sub = plainContainer.listen(telemetryLoggerProvider, (_, _) {});
    addTearDown(sub.close);

    plainContainer.read(activeRaceProvider.notifier).activeRace = race;
    await plainContainer.read(activeRaceProvider.notifier).start();
    await pumpEventQueue();

    // Nincs crash, és nincs telemetria (a plain stream nem ad nyers sort).
    expect(await telemetryRows(), isEmpty);
  });
}
