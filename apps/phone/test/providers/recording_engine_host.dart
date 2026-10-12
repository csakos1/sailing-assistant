import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:phone/engine/race_engine_host.dart';

/// Records the host calls; the snapshot and idle-stop streams and the
/// running service are driven by the test.
class RecordingEngineHost implements RaceEngineHost {
  final StreamController<RaceSnapshot> _snapshots =
      StreamController<RaceSnapshot>.broadcast();
  final StreamController<void> _idleStops = StreamController<void>.broadcast();
  final List<Race?> startedRaces = [];
  final List<Race?> raceCommands = [];
  final List<DateTime> startCommands = [];
  final List<DateTime> finishCommands = [];
  int stopCount = 0;
  int attachCount = 0;
  final List<Race?> attachedRaces = [];
  String? startError;

  /// What `isRunning` reports (a service left by an earlier app process).
  bool isServiceRunning = false;

  /// When set, start() waits for it: lets a test stop during the start.
  Completer<void>? startGate;

  void emit(RaceSnapshot snapshot) => _snapshots.add(snapshot);

  void emitIdleStop() => _idleStops.add(null);

  Future<void> close() async {
    await _snapshots.close();
    await _idleStops.close();
  }

  @override
  Future<String?> start({Race? race, Polar? polar}) async {
    startedRaces.add(race);
    await startGate?.future;
    return startError;
  }

  @override
  void sendRaceCommand(Race? race) => raceCommands.add(race);

  @override
  void sendStartCommand(DateTime at) => startCommands.add(at);

  @override
  void sendFinishCommand(DateTime at) => finishCommands.add(at);

  @override
  void sendRoundMarkCommand() {}

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<bool> isRunning() async => isServiceRunning;

  @override
  void attach({Race? race}) {
    attachCount++;
    attachedRaces.add(race);
  }

  @override
  Stream<void> get idleStops => _idleStops.stream;

  @override
  Future<void> dispose() async {}

  @override
  Stream<RaceSnapshot> get snapshots => _snapshots.stream;
}
