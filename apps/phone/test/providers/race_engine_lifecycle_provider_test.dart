import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';
import 'package:phone/providers/timer_factory_provider.dart';

import '../engine/fake_timers.dart';
import 'in_memory_repositories.dart';
import 'recording_engine_host.dart';

void main() {
  const markA = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  final startTime = DateTime.utc(2025, 6, 1, 10);
  final finishTime = DateTime.utc(2025, 6, 1, 12);
  final race = Race.create(id: 'race-1', name: 'Teszt', marks: const [markA]);
  final otherRace = Race.create(
    id: 'race-2',
    name: 'Masik',
    marks: const [markA],
  );

  late RecordingEngineHost host;
  late FakeTimers timers;
  late Map<String, DateTime> lastRecordings;
  late InMemoryRaceRepository repository;
  late InMemorySettingsRepository settings;
  late DateTime now;
  late ProviderContainer container;

  EngineSessionNotifier session() =>
      container.read(engineSessionProvider.notifier);
  void select(Race? selected) =>
      container.read(activeRaceProvider.notifier).activeRace = selected;

  RaceSnapshot snapshot({
    required RaceStatus? raceStatus,
    required ConnectionStatus connectionStatus,
    String? raceId,
    DateTime? tickTime,
    DateTime? raceFinishedAt,
    DateTime? raceStartedAt,
  }) => RaceSnapshot(
    eventCount: 0,
    boatState: BoatState(lastUpdate: tickTime ?? startTime),
    connectionStatus: connectionStatus,
    raceStatus: raceStatus,
    raceId: raceId,
    raceFinishedAt: raceFinishedAt,
    raceStartedAt: raceStartedAt,
    tickTime: tickTime ?? startTime,
  );

  // The probe found the boat while the app is in the foreground.
  Future<void> runFromProbe() async {
    session()
      ..appResumed()
      ..gatewayFound();
    await pumpEventQueue();
  }

  setUp(() {
    host = RecordingEngineHost();
    timers = FakeTimers();
    lastRecordings = {};
    repository = InMemoryRaceRepository();
    settings = InMemorySettingsRepository();
    // An hour after the start: a race started at startTime is recent.
    now = startTime.add(const Duration(hours: 1));
    container = ProviderContainer(
      overrides: [
        raceEngineHostProvider.overrideWithValue(host),
        timerFactoryProvider.overrideWithValue(timers.create),
        lastRecordingReaderProvider.overrideWithValue(
          (raceId) async => lastRecordings[raceId],
        ),
        clockProvider.overrideWithValue(() => now),
        raceRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider.overrideWithValue(settings),
        // A UTC wall clock: the local day does not depend on the machine.
        localWallClockProvider.overrideWithValue((instant) => instant.toUtc()),
      ],
    );
    addTearDown(host.close);
    addTearDown(repository.close);
    addTearDown(container.dispose);
    container.listen(raceEngineLifecycleProvider, (_, _) {});
  });

  group('starting the engine', () {
    test('a probe hit without a race starts in free mode', () async {
      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('a probe hit does not hand over a race not yet started', () async {
      // Arrange: the boot restore brought back a race not yet started.
      select(race);

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('a probe hit continues an active race after a restart', () async {
      // Arrange
      select(race.start(at: startTime));

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces.single?.status, RaceStatus.active);
    });

    test('a manual start hands over the selected race', () async {
      // Arrange
      select(race);

      // Act
      session().startManually();
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces.single?.id, 'race-1');
    });

    test('a finished selection starts in free mode', () async {
      // Arrange
      select(race.start(at: startTime).finish(at: finishTime));

      // Act
      session().startManually();
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('a manual start while loading starts the host with it', () async {
      // Act: the start arrives before the polar is loaded.
      session()
        ..appResumed()
        ..gatewayFound();
      select(race);
      select(race.start(at: startTime));
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces.single?.id, 'race-1');
      expect(host.startedRaces.single?.status, RaceStatus.active);
    });

    test('a stop during the host start stops the service again', () async {
      // Arrange
      host.startGate = Completer<void>();
      await runFromProbe();

      // Act
      session().stopManually();
      await pumpEventQueue();
      host.startGate?.complete();
      await pumpEventQueue();

      // Assert
      expect(host.stopCount, 2);
    });

    test('a manual stop stops the host', () async {
      // Arrange
      await runFromProbe();

      // Act
      session().stopManually();
      await pumpEventQueue();

      // Assert
      expect(host.stopCount, 1);
    });

    test('a service failure is reported and stops the session', () async {
      // Arrange
      host.startError = 'boom';

      // Act
      await runFromProbe();

      // Assert
      expect(container.read(engineServiceErrorProvider), 'boom');
      expect(container.read(engineSessionProvider), isA<EngineStopped>());
    });

    test('a successful start clears an earlier failure', () async {
      // Arrange
      host.startError = 'boom';
      await runFromProbe();
      host.startError = null;

      // Act
      session()
        ..appPaused()
        ..appResumed()
        ..gatewayFound();
      await pumpEventQueue();

      // Assert
      expect(container.read(engineServiceErrorProvider), isNull);
    });
  });

  group('the start and finish of a race', () {
    test('Rajt without a running engine starts it with the race', () async {
      // Arrange
      select(race);

      // Act
      select(race.start(at: startTime));
      await pumpEventQueue();

      // Assert
      expect(container.read(engineSessionProvider), isA<EngineRunning>());
      expect(host.startedRaces.single?.status, RaceStatus.active);
    });

    test('Rajt on the race already in the engine sends the start', () async {
      // Arrange
      select(race);
      session().startManually();
      await pumpEventQueue();

      // Act
      select(race.start(at: startTime));

      // Assert
      expect(host.startCommands, [startTime]);
      expect(host.raceCommands, isEmpty);
    });

    test('Rajt on a free-mode engine hands over the whole race', () async {
      // Arrange
      select(race);
      await runFromProbe();

      // Act
      select(race.start(at: startTime));

      // Assert
      expect(host.startCommands, isEmpty);
      expect(host.raceCommands.single?.status, RaceStatus.active);
    });

    test('the finish releases the race, the engine keeps running', () async {
      // Arrange
      final started = race.start(at: startTime);
      select(started);
      session().startManually();
      await pumpEventQueue();

      // Act
      select(started.finish(at: finishTime));

      // Assert
      expect(host.finishCommands, [finishTime]);
      expect(host.raceCommands, [null]);
      expect(host.stopCount, 0);
      expect(container.read(engineSessionProvider), isA<EngineRunning>());
    });

    test('a finish of a race not in the engine sends nothing', () async {
      // Arrange: race-2 is handed over by its start, then race-1 is
      // selected again (a selection change only).
      await runFromProbe();
      select(otherRace);
      select(otherRace.start(at: startTime));
      final started = race.start(at: startTime);
      select(started);
      host.raceCommands.clear();

      // Act: race-1 finishes while race-2 is in the engine.
      select(started.finish(at: finishTime));

      // Assert
      expect(host.finishCommands, isEmpty);
      expect(host.raceCommands, isEmpty);
    });

    test('a restore of an active race after the probe continues it', () async {
      // Arrange: the probe beat the boot restore.
      await runFromProbe();

      // Act: the age check reads the last recording asynchronously.
      select(race.start(at: startTime));
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.single?.status, RaceStatus.active);
    });

    test('a restore of a race not yet started is no command', () async {
      // Arrange
      await runFromProbe();

      // Act
      select(race);

      // Assert
      expect(host.raceCommands, isEmpty);
    });

    test('Rajt on another race keeps the race in progress', () async {
      // Arrange
      final started = race.start(at: startTime);
      select(started);
      await runFromProbe();
      select(otherRace);

      // Act
      select(otherRace.start(at: startTime));
      select(started);
      select(started.finish(at: finishTime));

      // Assert: race-1 still gets its finish, race-2 never got in.
      expect(host.raceCommands, [null]);
      expect(host.startCommands, isEmpty);
      expect(host.finishCommands, [finishTime]);
    });

    test('a race finished by the engine itself can be replaced', () async {
      // Arrange: race-1 runs, then the engine closes it at the last mark
      // without a Cel tap in the app.
      final started = race.start(at: startTime);
      select(started);
      await runFromProbe();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.finished,
          connectionStatus: const Connected(),
          raceId: 'race-1',
        ),
      );
      await pumpEventQueue();
      select(otherRace);

      // Act
      select(otherRace.start(at: startTime));

      // Assert: the engine was released, then race-2 handed over.
      expect(host.raceCommands.map((race) => race?.id), [null, 'race-2']);
    });

    test('an engine finish is saved and frees the engine', () async {
      // Arrange
      final started = race.start(at: startTime);
      select(started);
      await runFromProbe();
      final finishTick = startTime.add(const Duration(minutes: 50));

      // Act: the engine closed the race at the last mark; a late snapshot
      // still showing it must not close it again.
      for (var i = 0; i < 2; i++) {
        host.emit(
          snapshot(
            raceStatus: RaceStatus.finished,
            connectionStatus: const Connected(),
            raceId: 'race-1',
            tickTime: finishTick,
          ),
        );
      }
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, [null]);
      expect(repository.saved.single.finishedAt, finishTick);
      expect(container.read(activeRaceProvider)?.status, RaceStatus.finished);
      // The selection change does not send a second command.
      expect(host.finishCommands, isEmpty);
    });

    test('a new selection alone is not a command', () async {
      // Arrange
      select(race);
      await runFromProbe();

      // Act
      select(otherRace);

      // Assert
      expect(host.raceCommands, isEmpty);
      expect(host.startCommands, isEmpty);
    });
  });

  group('resuming an active race', () {
    test('a stale active race is not resumed by the probe', () async {
      // Arrange: the finish was forgotten; the last recording is old.
      final started = race.start(at: startTime);
      select(started);
      now = startTime.add(const Duration(days: 1));
      lastRecordings['race-1'] = startTime.add(const Duration(hours: 2));

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('an overnight race with a fresh recording is resumed', () async {
      // Arrange: started yesterday, recorded a minute ago.
      select(race.start(at: startTime));
      now = startTime.add(const Duration(hours: 18));
      lastRecordings['race-1'] = now.subtract(const Duration(minutes: 1));

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces.single?.id, 'race-1');
    });

    test('a late engine finish keeps the real finish time', () async {
      // Arrange: the UI sees the closed race only hours later.
      final started = race.start(at: startTime);
      select(started);
      await runFromProbe();
      final realFinish = startTime.add(const Duration(minutes: 50));

      // Act
      host.emit(
        snapshot(
          raceStatus: RaceStatus.finished,
          connectionStatus: const Connected(),
          raceId: 'race-1',
          raceFinishedAt: realFinish,
          tickTime: startTime.add(const Duration(hours: 4)),
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(repository.saved.single.finishedAt, realFinish);
    });

    test('an engine finish keeps a race started meanwhile', () async {
      // Arrange: an adopted engine, race-2 started by hand before its first
      // snapshot, which still shows the closed race-1.
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      select(otherRace);
      select(otherRace.start(at: startTime));

      // Act
      host.emit(
        snapshot(
          raceStatus: RaceStatus.finished,
          connectionStatus: const Connected(),
          raceId: 'race-1',
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-2']);
    });

    test('a restore while the engine races is no command', () async {
      // Arrange: an adopted engine reports race-1 in progress.
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.active,
          connectionStatus: const Connected(),
          raceId: 'race-1',
        ),
      );
      await pumpEventQueue();
      final started = race.start(at: startTime);

      // Act
      select(started);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, isEmpty);

      // Act: the Cel of the restored race reaches the adopted engine.
      select(started.finish(at: finishTime));

      // Assert
      expect(host.finishCommands, [finishTime]);
      expect(host.raceCommands, [null]);
    });

    test('a stale restore after the probe is no command', () async {
      // Arrange
      await runFromProbe();
      now = startTime.add(const Duration(days: 1));

      // Act
      select(race.start(at: startTime));
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, isEmpty);
    });

    test('a manual start ignores the age of the race', () async {
      // Arrange
      select(race.start(at: startTime));
      now = startTime.add(const Duration(days: 1));

      // Act
      session().startManually();
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces.single?.id, 'race-1');
    });
  });

  group('idle stop', () {
    test('an idle stop from the engine probes again', () async {
      // Arrange
      await runFromProbe();

      // Act
      host.emitIdleStop();
      await pumpEventQueue();

      // Assert
      expect(host.stopCount, 1);
      expect(container.read(engineSessionProvider), isA<EngineProbing>());
    });

    test('a missed idle stop is noticed on resume', () async {
      // Arrange: the app went to the background, the engine stopped.
      await runFromProbe();
      final lifecycle = container.read(raceEngineLifecycleProvider)
        ..onAppPaused();
      host.isServiceRunning = false;

      // Act
      await lifecycle.onAppResumed();

      // Assert
      expect(host.stopCount, 1);
      expect(container.read(engineSessionProvider), isA<EngineProbing>());
    });

    test('a running service keeps the session on resume', () async {
      // Arrange
      await runFromProbe();
      host.isServiceRunning = true;
      final lifecycle = container.read(raceEngineLifecycleProvider)
        ..onAppPaused();

      // Act
      await lifecycle.onAppResumed();

      // Assert
      expect(host.stopCount, 0);
      expect(container.read(engineSessionProvider), isA<EngineRunning>());
    });
  });

  group('adopting a running engine', () {
    test('a service left running is adopted, not restarted', () async {
      // Arrange
      host.isServiceRunning = true;

      // Act
      await container.read(raceEngineLifecycleProvider).onAppResumed();

      // Assert
      final running = container.read(engineSessionProvider) as EngineRunning;
      expect(running.cause, EngineStartCause.adopted);
      expect(host.attachCount, 1);
      expect(host.startedRaces, isEmpty);
    });

    test('an adopted engine that sends snapshots is kept', () async {
      // Arrange
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();

      // Act
      host.emit(
        snapshot(raceStatus: null, connectionStatus: const Connected()),
      );
      await pumpEventQueue();

      // Assert
      expect(timers.active, isEmpty);
      expect(host.startedRaces, isEmpty);
    });

    test('the adoption watchdog sleeps in the background', () async {
      // Arrange
      host.isServiceRunning = true;
      final lifecycle = container.read(raceEngineLifecycleProvider);
      await lifecycle.onAppResumed();

      // Act
      lifecycle.onAppPaused();

      // Assert
      expect(timers.active, isEmpty);

      // Act: back in the foreground, still no snapshot.
      await lifecycle.onAppResumed();

      // Assert
      expect(timers.active, hasLength(1));
      expect(host.startedRaces, isEmpty);
    });

    test('a pause during the resume check keeps the background', () async {
      // Arrange
      final lifecycle = container.read(raceEngineLifecycleProvider);

      // Act: the pause arrives while the service check is awaited.
      final resumed = lifecycle.onAppResumed();
      lifecycle.onAppPaused();
      await resumed;

      // Assert
      expect(container.read(engineSessionProvider), isA<EngineStopped>());
    });

    test('a silent adopted engine is restarted', () async {
      // Arrange
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();

      // Act
      timers.active.single.fire();
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('the Cel of the adopted active race finishes it', () async {
      // Arrange
      final started = race.start(at: startTime);
      select(started);
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();

      // Act
      select(started.finish(at: finishTime));

      // Assert
      expect(host.finishCommands, [finishTime]);
      expect(host.raceCommands, [null]);
    });
  });

  group("the day's race (ADR 0055 T4)", () {
    // The clock of setUp: an hour after startTime, the same local day.
    final setUpNow = startTime.add(const Duration(hours: 1));
    final scheduledStart = setUpNow.add(const Duration(hours: 2));
    final scheduledRace = Race.create(
      id: 'race-3',
      name: 'Tervezett',
      marks: const [markA],
    ).copyWith(scheduledStartAt: scheduledStart);
    final laterRace = Race.create(
      id: 'race-4',
      name: 'Kesobbi',
      marks: const [markA],
    ).copyWith(scheduledStartAt: scheduledStart.add(const Duration(hours: 1)));

    test("a probe hit starts with today's scheduled race", () async {
      // Arrange
      repository.put(scheduledRace);

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces.single?.id, 'race-3');
    });

    test("today's manual choice wins over the earliest race", () async {
      // Arrange
      repository
        ..put(scheduledRace)
        ..put(laterRace);
      settings.choice = InstrumentsRaceChoice(
        raceId: 'race-4',
        chosenOnLocalDay: setUpNow,
      );

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces.single?.id, 'race-4');
    });

    test('a new manual choice switches the engine at once', () async {
      // Arrange: the engine leads to the earliest race of the day.
      repository
        ..put(scheduledRace)
        ..put(laterRace);
      await runFromProbe();

      // Act: the switcher stores the later race and tells the lifecycle.
      settings.choice = InstrumentsRaceChoice(
        raceId: 'race-4',
        chosenOnLocalDay: setUpNow,
      );
      container.read(raceEngineLifecycleProvider).onInstrumentsChoiceChanged();
      await pumpEventQueue();

      // Assert
      expect(host.startedRaces.single?.id, 'race-3');
      expect(host.raceCommands.map((race) => race?.id), ['race-4']);
    });

    test('a manual choice does not replace a race in progress', () async {
      // Arrange: the engine runs the day's earliest race, then reports a
      // race in progress (e.g. started on its own).
      repository
        ..put(scheduledRace)
        ..put(laterRace);
      await runFromProbe();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.active,
          connectionStatus: const Connected(),
          raceId: 'race-3',
        ),
      );
      await pumpEventQueue();

      // Act: the rule alone would now send race-4.
      settings.choice = InstrumentsRaceChoice(
        raceId: 'race-4',
        chosenOnLocalDay: setUpNow,
      );
      container.read(raceEngineLifecycleProvider).onInstrumentsChoiceChanged();
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, isEmpty);
    });

    test('a race scheduled later is sent to a free-mode engine', () async {
      // Arrange
      await runFromProbe();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-3']);
    });

    test('an edited start time sends the fresh race again', () async {
      // Arrange
      repository.put(scheduledRace);
      await runFromProbe();
      final postponed = scheduledRace.copyWith(
        scheduledStartAt: scheduledStart.add(const Duration(minutes: 30)),
      );

      // Act
      repository.put(postponed);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, [postponed]);
    });

    test('an expired start window frees the engine on resume', () async {
      // Arrange
      repository.put(scheduledRace);
      await runFromProbe();
      host.isServiceRunning = true;
      // The window end is exclusive: at exactly 3 hours it is closed.
      now = scheduledStart.add(const Duration(hours: 3));

      // Act
      await container.read(raceEngineLifecycleProvider).onAppResumed();

      // Assert
      expect(host.raceCommands, [null]);
    });

    test('an adopted free engine is given the day race', () async {
      // Arrange: a forgotten active race is selected, but the adopted
      // engine reports free mode.
      final stale = race.start(at: startTime.subtract(const Duration(days: 1)));
      select(stale);
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      host.emit(
        snapshot(raceStatus: null, connectionStatus: const Connected()),
      );
      await pumpEventQueue();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-3']);
    });

    test('a manual start before the first adopted snapshot is kept', () async {
      // Arrange: the first snapshot was made before the manual start.
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      // A stale start: the rule alone would not resume race-2, it would
      // send the day's race-3.
      select(otherRace);
      select(otherRace.start(at: startTime.subtract(const Duration(hours: 6))));
      host.emit(
        snapshot(raceStatus: null, connectionStatus: const Connected()),
      );
      await pumpEventQueue();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-2']);
    });

    test('an adopted race not yet started belongs to the rule', () async {
      // Arrange: after an app restart the engine still leads to a race the
      // rule chose earlier (since deleted); only the rule puts a race not
      // yet started into the engine.
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.notStarted,
          connectionStatus: const Connected(),
          raceId: 'race-9',
        ),
      );
      await pumpEventQueue();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-3']);
    });

    test('a manual choice switches an adopted pre-start engine', () async {
      // Arrange: the restarted app adopts an engine leading to race-3.
      repository
        ..put(scheduledRace)
        ..put(laterRace);
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.notStarted,
          connectionStatus: const Connected(),
          raceId: 'race-3',
        ),
      );
      await pumpEventQueue();
      host.raceCommands.clear();

      // Act
      settings.choice = InstrumentsRaceChoice(
        raceId: 'race-4',
        chosenOnLocalDay: setUpNow,
      );
      container.read(raceEngineLifecycleProvider).onInstrumentsChoiceChanged();
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands.map((race) => race?.id), ['race-4']);
    });

    test('an adopted race in progress unknown to the app is kept', () async {
      // Arrange: a race started by hand in an earlier app process.
      host.isServiceRunning = true;
      await container.read(raceEngineLifecycleProvider).onAppResumed();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.active,
          connectionStatus: const Connected(),
          raceId: 'race-9',
        ),
      );
      await pumpEventQueue();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, isEmpty);
    });

    test('a failed race read starts in free mode', () async {
      // Arrange
      repository
        ..put(scheduledRace)
        ..isReadFailing = true;

      // Act
      await runFromProbe();

      // Assert
      expect(host.startedRaces, [null]);
    });

    test('a race in progress is not replaced', () async {
      // Arrange
      final started = race.start(at: startTime);
      select(started);
      await runFromProbe();
      host.emit(
        snapshot(
          raceStatus: RaceStatus.active,
          connectionStatus: const Connected(),
          raceId: 'race-1',
        ),
      );
      await pumpEventQueue();

      // Act
      repository.put(scheduledRace);
      await pumpEventQueue();

      // Assert
      expect(host.raceCommands, isEmpty);
    });

    test("the engine's own start is saved and selected", () async {
      // Arrange
      repository.put(scheduledRace);
      await runFromProbe();

      // Act: the engine started the race at its scheduled time.
      for (var i = 0; i < 2; i++) {
        host.emit(
          snapshot(
            raceStatus: RaceStatus.active,
            connectionStatus: const Connected(),
            raceId: 'race-3',
            raceStartedAt: scheduledStart,
          ),
        );
      }
      await pumpEventQueue();

      // Assert: saved once, with the scheduled time.
      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.startedAt, scheduledStart);
      final selected = container.read(activeRaceProvider);
      expect(selected?.id, 'race-3');
      expect(selected?.status, RaceStatus.active);
      // The engine already runs the race: no command goes out for it.
      expect(host.raceCommands, isEmpty);
    });

    test('a manual start is not overwritten by the engine', () async {
      // Arrange
      final started = race.start(at: startTime);
      repository.put(started);
      select(started);
      await runFromProbe();

      // Act
      host.emit(
        snapshot(
          raceStatus: RaceStatus.active,
          connectionStatus: const Connected(),
          raceId: 'race-1',
          raceStartedAt: startTime.add(const Duration(seconds: 1)),
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(repository.saved, isEmpty);
      expect(container.read(activeRaceProvider), started);
    });
  });
}
