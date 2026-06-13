import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/race_engine_host.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';
import 'package:phone/providers/race_engine_session_provider.dart';

void main() {
  const markA = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  const markB = Mark(
    sequence: 2,
    name: 'B',
    position: Coordinate(latitude: 46.8, longitude: 17.9),
  );
  final fixedNow = DateTime.utc(2025, 6, 1, 10);
  final race = Race.create(
    id: 'race-1',
    name: 'Teszt',
    marks: const [markA, markB],
  );

  late _RecordingHost host;
  late ProviderContainer container;

  setUp(() {
    host = _RecordingHost();
    container = ProviderContainer(
      overrides: [raceEngineHostProvider.overrideWithValue(host)],
    );
    addTearDown(container.dispose);
    container.listen(raceEngineLifecycleProvider, (_, _) {});
  });

  test('session true → host.start az aktív race-szel', () async {
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();

    expect(host.startedRaces, hasLength(1));
    expect(host.startedRaces.single.id, 'race-1');
  });

  test('session false → host.stop', () async {
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();
    container.read(raceEngineSessionProvider.notifier).stop();
    await pumpEventQueue();

    expect(host.stopCount, 1);
  });

  test('notStarted→active átmenet → sendStartCommand', () async {
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();

    container.read(activeRaceProvider.notifier).activeRace = race.start(
      at: fixedNow,
    );
    await pumpEventQueue();

    expect(host.startCommands, hasLength(1));
    expect(host.startCommands.single, fixedNow);
  });

  test('active→finished → finish-parancs és a session leáll', () async {
    final started = race.start(at: fixedNow);
    container.read(activeRaceProvider.notifier).activeRace = started;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();

    container.read(activeRaceProvider.notifier).activeRace = started.finish(
      at: fixedNow,
    );
    await pumpEventQueue();

    expect(host.startCommands, isEmpty);
    expect(host.finishCommands, hasLength(1));
    expect(host.finishCommands.single, fixedNow);
    // A cél lezárja a sessiont (ADR 0017 A12) → host.stop + flag false.
    expect(host.stopCount, 1);
    expect(container.read(raceEngineSessionProvider), isFalse);
  });

  test('kiválasztás-csere (más race) → nincs parancs', () async {
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();

    container.read(activeRaceProvider.notifier).activeRace = Race.create(
      id: 'race-2',
      name: 'Másik',
      marks: const [markA],
    );
    await pumpEventQueue();

    expect(host.startCommands, isEmpty);
    expect(host.finishCommands, isEmpty);
  });

  test('service-hiba → engineServiceErrorProvider beáll', () async {
    host.startError = 'boom';
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();

    expect(container.read(engineServiceErrorProvider), 'boom');
  });

  test('leállítás nullázza a service-hibát', () async {
    host.startError = 'boom';
    container.read(activeRaceProvider.notifier).activeRace = race;
    container.read(raceEngineSessionProvider.notifier).start();
    await pumpEventQueue();
    expect(container.read(engineServiceErrorProvider), 'boom');

    container.read(raceEngineSessionProvider.notifier).stop();
    await pumpEventQueue();

    expect(container.read(engineServiceErrorProvider), isNull);
  });
}

/// Teszt-fake: rögzíti a hívásokat, és konfigurálható start-hibát ad.
class _RecordingHost implements RaceEngineHost {
  final List<Race> startedRaces = [];
  final List<DateTime> startCommands = [];
  final List<DateTime> finishCommands = [];
  int stopCount = 0;
  String? startError;

  @override
  void sendRoundMarkCommand() {}

  @override
  Future<String?> start(Race race) async {
    startedRaces.add(race);
    return startError;
  }

  @override
  void sendStartCommand(DateTime at) => startCommands.add(at);

  @override
  void sendFinishCommand(DateTime at) => finishCommands.add(at);

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Stream<RaceSnapshot> get snapshots => const Stream<RaceSnapshot>.empty();
}
