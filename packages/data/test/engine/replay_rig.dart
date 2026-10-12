import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:data/data.dart';
import 'package:data/src/nmea/pipeline/nmea_event_pipeline.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Shared parts of the engine replay tests: the fixture, its marks and a rig
// that feeds the log second by second through the real pipeline.

/// The synthetic mark-rounding leg in tools/sample_logs (see its README).
const movingMarkRoundingFixture = 'moving_mark_rounding.nmea';

/// M1, the mark the fixture passes at ~8 m (sample_logs/README).
const fixtureMarkOne = Mark(
  sequence: 1,
  name: 'M1',
  position: Coordinate(latitude: 47.5850, longitude: 18.8550),
);

/// M2, ~300 m NE of M1; the fixture bears away towards it.
const fixtureMarkTwo = Mark(
  sequence: 2,
  name: 'M2',
  position: Coordinate(latitude: 47.5869, longitude: 18.8578),
);

/// Wires the engine to a fake source that the real pipeline feeds, a shared
/// clock and recording loggers.
class ReplayRig {
  ReplayRig({required DateTime logStart}) : _clock = logStart;

  final _ReplaySource _source = _ReplaySource();
  final RecordingTelemetryLogger telemetryLogger = RecordingTelemetryLogger();
  final RecordingSnapshotLogger snapshotLogger = RecordingSnapshotLogger();
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

/// The distance to the guided mark; infinite without a prediction, so a
/// missing prediction fails the distance assertions instead of passing.
double distanceToMarkMeters(RaceSnapshot snapshot) =>
    snapshot.prediction?.distanceToMark.meters ?? double.infinity;

/// The bare sentences of the fixture, without the "HH:MM:SS.mmm " prefix,
/// grouped by the second they were logged in (index 0 = the first second).
List<List<String>> groupBySecond(List<String> lines) {
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

/// The fixture lives in tools/sample_logs at the repository root; the test
/// runs from the package directory, so it is looked up upwards.
List<String> readFixtureLines(String name) {
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

class RecordingTelemetryLogger implements TelemetryLogger {
  final List<TelemetryRecord> records = [];

  @override
  Future<void> log(TelemetryRecord record) async => records.add(record);

  @override
  Future<void> dispose() async {}
}

class RecordingSnapshotLogger implements SnapshotLogger {
  final List<({String raceId, RaceSnapshot snapshot})> entries = [];

  @override
  Future<void> log(String raceId, RaceSnapshot snapshot) async =>
      entries.add((raceId: raceId, snapshot: snapshot));

  @override
  Future<void> dispose() async {}
}
