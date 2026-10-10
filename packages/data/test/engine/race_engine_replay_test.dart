import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:data/data.dart';
import 'package:data/src/nmea/pipeline/nmea_event_pipeline.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Replay test of the whole engine life cycle (ADR 0054 E4) on the recorded
// synthetic fixture tools/sample_logs/moving_mark_rounding.nmea: the boat
// starts ~150 m south of M1, passes it at ~8 m and bears away towards M2.
// Every second of the log is fed through the real NmeaEventPipeline into
// the engine, then one tick follows - the tick sees the whole second, as
// on the boat.

const _fixtureName = 'moving_mark_rounding.nmea';

// The mark coordinates the fixture was generated for (sample_logs/README).
const _markOne = Mark(
  sequence: 1,
  name: 'M1',
  position: Coordinate(latitude: 47.5850, longitude: 18.8550),
);
const _markTwo = Mark(
  sequence: 2,
  name: 'M2',
  position: Coordinate(latitude: 47.5869, longitude: 18.8578),
);

// The seconds of the replay at which the "host" sends its commands.
const _raceCommandSecond = 10;
const _startCommandSecond = 20;

void main() {
  final logStart = DateTime.utc(2026, 6, 4, 10);
  late List<List<String>> secondsOfLog;
  late _ReplayRig rig;

  DateTime at(int second) => logStart.add(Duration(seconds: second));

  setUpAll(() {
    secondsOfLog = _groupBySecond(_readFixtureLines(_fixtureName));
    // The scenario needs the whole log, with data in every second.
    if (secondsOfLog.length <= 100 ||
        secondsOfLog.any((sentences) => sentences.isEmpty)) {
      throw StateError('$_fixtureName no longer fits this test');
    }
  });

  setUp(() async {
    rig = _ReplayRig(logStart: logStart);
    await rig.start();
  });

  tearDown(() async {
    await rig.dispose();
  });

  group('single-mark race', () {
    final race = Race.create(
      id: 'replay-single',
      name: 'Replay egy bója',
      marks: const [_markOne],
    );

    // Replays the full log: race command at 10 s, start at 20 s, and the
    // "host" releases the race 3 s after the engine finished it on its own
    // (like RaceEngineLifecycle does on the snapshot's finished status).
    // Returns the second at which the engine finished the race.
    Future<int> replayWithAutoFinish() async {
      int? finishedSecond;
      for (var second = 0; second < secondsOfLog.length; second++) {
        if (second == _raceCommandSecond) {
          expect(rig.engine.applyRaceCommand(race), isTrue);
        }
        if (second == _startCommandSecond) {
          rig.engine.applyStartCommand(at(second));
        }
        if (finishedSecond != null && second == finishedSecond + 3) {
          expect(rig.engine.applyRaceCommand(null), isTrue);
        }
        await rig.playSecond(at(second), secondsOfLog[second]);
        if (finishedSecond == null &&
            rig.snapshots.last.raceStatus == RaceStatus.finished) {
          finishedSecond = second;
        }
      }
      return finishedSecond ?? fail('M1 was never rounded');
    }

    test('runs free, pre-start, active, auto-finish, then free', () async {
      // Arrange / Act
      final finishedSecond = await replayWithAutoFinish();

      // Assert
      final snapshots = rig.snapshots;
      expect(snapshots, hasLength(secondsOfLog.length));

      // Free mode: the instruments work, but there is no race.
      for (final snapshot in snapshots.take(_raceCommandSecond)) {
        expect(snapshot.raceStatus, isNull);
        expect(snapshot.raceId, isNull);
        expect(snapshot.prediction, isNull);
      }
      expect(snapshots[_raceCommandSecond - 1].boatState.position, isNotNull);
      expect(snapshots[_raceCommandSecond - 1].wind, isNotNull);

      // Pre-start: the race is in the engine and guides to M1.
      for (final snapshot in snapshots.sublist(
        _raceCommandSecond,
        _startCommandSecond,
      )) {
        expect(snapshot.raceStatus, RaceStatus.notStarted);
        expect(snapshot.raceId, race.id);
        expect(snapshot.prediction?.mark.name, 'M1');
      }

      // Active until the rounding, which the README places at ~63 s.
      expect(finishedSecond, inInclusiveRange(60, 66));
      for (final snapshot in snapshots.sublist(
        _startCommandSecond,
        finishedSecond,
      )) {
        expect(snapshot.raceStatus, RaceStatus.active);
        expect(snapshot.prediction?.mark.name, 'M1');
      }
      final closestApproach = snapshots
          .sublist(_startCommandSecond, finishedSecond)
          .map(_distanceToMarkMeters)
          .reduce(math.min);
      expect(closestApproach, lessThan(50));

      // The finishing tick: finished at the tick time, no mark left.
      final finishSnapshot = snapshots[finishedSecond];
      expect(finishSnapshot.raceId, race.id);
      expect(finishSnapshot.raceFinishedAt, at(finishedSecond));
      expect(finishSnapshot.prediction, isNull);

      // Until the host releases it, the engine keeps the finished race.
      for (final snapshot in snapshots.sublist(
        finishedSecond,
        finishedSecond + 3,
      )) {
        expect(snapshot.raceStatus, RaceStatus.finished);
        expect(snapshot.raceId, race.id);
      }

      // Released: free mode again until the end of the log.
      for (final snapshot in snapshots.sublist(finishedSecond + 3)) {
        expect(snapshot.raceStatus, isNull);
        expect(snapshot.raceId, isNull);
        expect(snapshot.raceFinishedAt, isNull);
        expect(snapshot.prediction, isNull);
      }
    });

    test('records only from the start to the finish', () async {
      // Arrange / Act
      final finishedSecond = await replayWithAutoFinish();

      // Assert - telemetry: every sentence of seconds 20..finish. The
      // sentences of the finishing second arrive before its tick, while
      // the race is still active, so they are recorded too.
      final expectedSentences = secondsOfLog
          .sublist(_startCommandSecond, finishedSecond + 1)
          .expand((sentences) => sentences)
          .toList();
      final records = rig.telemetryLogger.records;
      expect(
        records.map((record) => record.rawSentence).toList(),
        expectedSentences,
      );
      expect(records.map((record) => record.raceId), everyElement(race.id));
      expect(records.first.timestamp, at(_startCommandSecond));
      expect(records.last.timestamp, at(finishedSecond));

      // Snapshot log: the active ticks only; the finishing one is not.
      final entries = rig.snapshotLogger.entries;
      expect(entries, hasLength(finishedSecond - _startCommandSecond));
      expect(entries.map((entry) => entry.raceId), everyElement(race.id));
      expect(
        entries.map((entry) => entry.snapshot.raceStatus),
        everyElement(RaceStatus.active),
      );
      expect(entries.first.snapshot.tickTime, at(_startCommandSecond));
      expect(entries.last.snapshot.tickTime, at(finishedSecond - 1));
    });
  });

  group('two-mark race', () {
    final race = Race.create(
      id: 'replay-two',
      name: 'Replay két bója',
      marks: const [_markOne, _markTwo],
    );

    Future<void> replayWithoutFinish() async {
      for (var second = 0; second < secondsOfLog.length; second++) {
        if (second == _raceCommandSecond) {
          expect(rig.engine.applyRaceCommand(race), isTrue);
        }
        if (second == _startCommandSecond) {
          rig.engine.applyStartCommand(at(second));
        }
        await rig.playSecond(at(second), secondsOfLog[second]);
      }
    }

    test('steps from M1 to M2 and keeps racing', () async {
      // Arrange / Act
      await replayWithoutFinish();

      // Assert
      final activeSnapshots = rig.snapshots.sublist(_startCommandSecond);
      expect(
        activeSnapshots.map((snapshot) => snapshot.raceStatus),
        everyElement(RaceStatus.active),
      );
      expect(
        activeSnapshots.map((snapshot) => snapshot.raceFinishedAt),
        everyElement(isNull),
      );

      final markNames = activeSnapshots
          .map((snapshot) => snapshot.prediction?.mark.name)
          .toList();
      final stepIndex = markNames.indexOf('M2');
      expect(stepIndex, isPositive, reason: 'M1 was never rounded');
      expect(_startCommandSecond + stepIndex, inInclusiveRange(60, 66));
      // One clean step: M1 before it, M2 from it on, no flapping back.
      expect(markNames.sublist(0, stepIndex), everyElement('M1'));
      expect(markNames.sublist(stepIndex), everyElement('M2'));

      // The fixture bears away towards M2: the distance shrinks.
      expect(
        _distanceToMarkMeters(activeSnapshots.last),
        lessThan(_distanceToMarkMeters(activeSnapshots[stepIndex])),
      );
    });

    test('records every active tick through the rounding', () async {
      // Arrange / Act
      await replayWithoutFinish();

      // Assert
      final entries = rig.snapshotLogger.entries;
      expect(entries, hasLength(secondsOfLog.length - _startCommandSecond));
      expect(entries.map((entry) => entry.raceId), everyElement(race.id));
    });
  });
}

// Wires the engine to a fake source that the real pipeline feeds, a shared
// clock and recording loggers.
class _ReplayRig {
  _ReplayRig({required DateTime logStart}) : _clock = logStart;

  final _ReplaySource _source = _ReplaySource();
  final _RecordingTelemetryLogger telemetryLogger = _RecordingTelemetryLogger();
  final _RecordingSnapshotLogger snapshotLogger = _RecordingSnapshotLogger();
  final StreamController<DateTime> _ticks = StreamController<DateTime>();
  final List<RaceSnapshot> snapshots = [];
  late final RaceEngine engine = RaceEngine(
    nmeaStream: _source,
    telemetryLogger: telemetryLogger,
    snapshotLogger: snapshotLogger,
    tickSource: _ticks.stream,
    now: () => _clock,
  );
  // One pipeline for the whole replay: its wind state carries across
  // seconds, like the single pipeline of a live connection.
  late final NmeaEventPipeline _pipeline = NmeaEventPipeline(
    now: () => _clock,
  );
  DateTime _clock;
  StreamSubscription<RaceSnapshot>? _snapshotSubscription;

  Future<void> start() async {
    _snapshotSubscription = engine.snapshots.listen(snapshots.add);
    await engine.start();
  }

  // One second of the log: the decoded events, the raw sentences, then the
  // tick at the same instant.
  Future<void> playSecond(DateTime instant, List<String> sentences) async {
    _clock = instant;
    final payload = utf8.encode('${sentences.join('\n')}\n');
    final events = await _pipeline
        .transform(Stream<List<int>>.value(payload))
        .toList();
    events.forEach(_source.emitEvent);
    sentences.forEach(_source.emitRaw);
    await pumpEventQueue();
    _ticks.add(instant);
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    await engine.dispose();
    await _snapshotSubscription?.cancel();
    await _source.close();
    await _ticks.close();
  }
}

// The distance to the guided mark; infinite without a prediction, so a
// missing prediction fails the distance assertions instead of passing.
double _distanceToMarkMeters(RaceSnapshot snapshot) =>
    snapshot.prediction?.distanceToMark.meters ?? double.infinity;

// The bare sentences of the fixture, without the "HH:MM:SS.mmm " prefix,
// grouped by the second they were logged in (index 0 = the first second).
List<List<String>> _groupBySecond(List<String> lines) {
  final prefixed = RegExp(r'^(\d{2}):(\d{2}):(\d{2})\.\d{3} (\$.+)$');
  final bySecond = <List<String>>[];
  int? firstSecond;
  for (final line in lines) {
    final match = prefixed.firstMatch(line.trim());
    if (match == null) {
      continue;
    }
    // The groups are not optional in the pattern: a match has all four.
    final secondOfDay =
        int.parse(match.group(1)!) * 3600 +
        int.parse(match.group(2)!) * 60 +
        int.parse(match.group(3)!);
    final offset = secondOfDay - (firstSecond ??= secondOfDay);
    if (offset < 0) {
      throw StateError('the log goes back in time or past midnight: $line');
    }
    while (bySecond.length <= offset) {
      bySecond.add(<String>[]);
    }
    bySecond[offset].add(match.group(4)!);
  }
  return bySecond;
}

// The fixture lives in tools/sample_logs at the repository root; the test
// runs from the package directory, so it is looked up upwards.
List<String> _readFixtureLines(String name) {
  var directory = Directory.current.absolute;
  while (true) {
    final file = File('${directory.path}/tools/sample_logs/$name');
    if (file.existsSync()) {
      return file.readAsLinesSync();
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('tools/sample_logs/$name not found');
    }
    directory = parent;
  }
}

// A source the rig feeds by hand; always connected.
class _ReplaySource implements NmeaStream, RawNmeaLineSource {
  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();
  final StreamController<String> _raw = StreamController<String>.broadcast();
  final StreamController<ConnectionStatus> _status =
      StreamController<ConnectionStatus>.broadcast();

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
  ConnectionStatus get currentStatus => const Connected();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}

class _RecordingTelemetryLogger implements TelemetryLogger {
  final List<TelemetryRecord> records = [];

  @override
  Future<void> log(TelemetryRecord record) async => records.add(record);

  @override
  Future<void> dispose() async {}
}

class _RecordingSnapshotLogger implements SnapshotLogger {
  final List<({String raceId, RaceSnapshot snapshot})> entries = [];

  @override
  Future<void> log(String raceId, RaceSnapshot snapshot) async =>
      entries.add((raceId: raceId, snapshot: snapshot));

  @override
  Future<void> dispose() async {}
}
