import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'replay_rig.dart';

// Replay test of the scheduled start (ADR 0055 D2, D6, D7, T5) on the
// synthetic fixture tools/sample_logs/moving_mark_rounding.nmea: the boat
// starts ~150 m south of M1 and sails north at ~5 kn, passing a start point
// placed on its track ~94 m ahead. No start command is sent: the engine
// starts the race by itself at the scheduled time.

// The start point on the fixture's track, ~56 m south of M1: the boat
// reaches it at ~37 s, so it keeps closing in until a start at 25 s.
const _startPoint = StartPoint(
  name: 'Rajthely',
  position: Coordinate(latitude: 47.5845, longitude: 18.8551),
);

// The second at which the "host" hands the race to the running engine.
const _raceCommandSecond = 10;

// The scheduled start of the on-time scenario.
const _scheduledStartSecond = 25;

void main() {
  final logStart = DateTime.utc(2026, 6, 4, 10);
  late List<List<String>> secondsOfLog;
  late ReplayRig rig;

  DateTime at(int second) => logStart.add(Duration(seconds: second));

  setUpAll(() {
    secondsOfLog = groupBySecond(readFixtureLines(movingMarkRoundingFixture));
    // The scenario needs the whole log, with data in every second.
    if (secondsOfLog.length <= 100 ||
        secondsOfLog.any((sentences) => sentences.isEmpty)) {
      throw StateError('$movingMarkRoundingFixture no longer fits this test');
    }
  });

  setUp(() async {
    rig = ReplayRig(logStart: logStart);
    await rig.start();
  });

  tearDown(() async {
    await rig.dispose();
  });

  // Replays the full log; the race goes to the engine at 10 s and nothing
  // else is sent, so every start comes from the engine itself.
  Future<void> replay(Race race) async {
    for (var second = 0; second < secondsOfLog.length; second++) {
      if (second == _raceCommandSecond) {
        expect(rig.engine.applyRaceCommand(race), isTrue);
      }
      await rig.playSecond(at(second), secondsOfLog[second]);
    }
  }

  // The second of the first snapshot with the given status, or a failure.
  int firstSecondWith(RaceStatus status) {
    final index = rig.snapshots.indexWhere(
      (snapshot) => snapshot.raceStatus == status,
    );
    return index >= 0 ? index : fail('no snapshot is $status');
  }

  group('a start scheduled during the replay', () {
    final race = Race.create(
      id: 'replay-scheduled',
      name: 'Replay tervezett rajt',
      marks: const [fixtureMarkOne, fixtureMarkTwo],
      scheduledStartAt: at(_scheduledStartSecond),
      startPoint: _startPoint,
    );

    test('guides to the start point, starts on time, then to M1', () async {
      // Arrange / Act
      await replay(race);

      // Assert
      final snapshots = rig.snapshots;
      expect(snapshots, hasLength(secondsOfLog.length));

      // Pre-start: guided to the start point, closing in, not started.
      final preStart = snapshots.sublist(
        _raceCommandSecond,
        _scheduledStartSecond,
      );
      for (final snapshot in preStart) {
        expect(snapshot.raceStatus, RaceStatus.notStarted);
        expect(snapshot.raceId, race.id);
        expect(snapshot.raceStartedAt, isNull);
        expect(snapshot.prediction?.mark.name, _startPoint.name);
      }
      final approach =
          distanceToMarkMeters(preStart.first) -
          distanceToMarkMeters(preStart.last);
      // ~14 s at ~5 kn is ~36 m closer.
      expect(approach, greaterThan(25));

      // The start: on the scheduled tick, with the scheduled time.
      expect(firstSecondWith(RaceStatus.active), _scheduledStartSecond);
      final racing = snapshots.sublist(_scheduledStartSecond);
      expect(
        racing.map((snapshot) => snapshot.raceStatus),
        everyElement(RaceStatus.active),
      );
      expect(
        racing.map((snapshot) => snapshot.raceStartedAt),
        everyElement(at(_scheduledStartSecond)),
      );

      // After the start: M1, then one clean step to M2 at ~63 s.
      final markNames = racing
          .map((snapshot) => snapshot.prediction?.mark.name)
          .toList();
      final stepIndex = markNames.indexOf('M2');
      expect(stepIndex, isPositive, reason: 'M1 was never rounded');
      expect(_scheduledStartSecond + stepIndex, inInclusiveRange(60, 66));
      expect(markNames.sublist(0, stepIndex), everyElement('M1'));
      expect(markNames.sublist(stepIndex), everyElement('M2'));
    });

    test('records nothing before the start', () async {
      // Arrange / Act
      await replay(race);

      // Assert - telemetry: the sentences of the start second arrive
      // before its tick, while the race is still not started, so the
      // recording begins with the next second (ADR 0055 T3: up to ~1 s
      // between the scheduled time and the first tick is not recorded).
      final expectedSentences = secondsOfLog
          .sublist(_scheduledStartSecond + 1)
          .expand((sentences) => sentences)
          .toList();
      final records = rig.telemetryLogger.records;
      expect(
        records.map((record) => record.rawSentence).toList(),
        expectedSentences,
      );
      expect(records.map((record) => record.raceId), everyElement(race.id));
      expect(records.first.timestamp, at(_scheduledStartSecond + 1));

      // Snapshot log: every tick from the starting one on.
      final entries = rig.snapshotLogger.entries;
      expect(entries, hasLength(secondsOfLog.length - _scheduledStartSecond));
      expect(entries.map((entry) => entry.raceId), everyElement(race.id));
      expect(entries.first.snapshot.tickTime, at(_scheduledStartSecond));
    });
  });

  group('a start scheduled before the replay', () {
    // Half an hour late, inside the 3-hour window (ADR 0055 D7).
    final scheduledStartAt = logStart.subtract(const Duration(minutes: 30));
    final race = Race.create(
      id: 'replay-late',
      name: 'Replay késői rajt',
      marks: const [fixtureMarkOne],
      scheduledStartAt: scheduledStartAt,
      startPoint: _startPoint,
    );

    test('starts on the first tick with the scheduled time', () async {
      // Arrange / Act
      await replay(race);

      // Assert - free mode until the race arrives.
      final snapshots = rig.snapshots;
      for (final snapshot in snapshots.take(_raceCommandSecond)) {
        expect(snapshot.raceStatus, isNull);
        expect(snapshot.raceId, isNull);
      }

      // Started at once, never guided to the start point.
      expect(firstSecondWith(RaceStatus.active), _raceCommandSecond);
      expect(snapshots[_raceCommandSecond].raceStartedAt, scheduledStartAt);
      expect(snapshots[_raceCommandSecond].prediction?.mark.name, 'M1');

      // The single mark finishes the race at the rounding, ~63 s in.
      final finishedSecond = firstSecondWith(RaceStatus.finished);
      expect(finishedSecond, inInclusiveRange(60, 66));
      for (final snapshot in snapshots.sublist(
        _raceCommandSecond,
        finishedSecond,
      )) {
        expect(snapshot.raceStatus, RaceStatus.active);
        expect(snapshot.raceStartedAt, scheduledStartAt);
        expect(snapshot.prediction?.mark.name, 'M1');
      }
      expect(snapshots[finishedSecond].raceFinishedAt, at(finishedSecond));
      expect(snapshots[finishedSecond].raceStartedAt, scheduledStartAt);
    });

    test('records from the start tick, not the scheduled time', () async {
      // Arrange / Act
      await replay(race);

      // Assert - the missed half hour cannot be recorded; the telemetry
      // begins with the second after the start tick.
      final finishedSecond = firstSecondWith(RaceStatus.finished);
      final records = rig.telemetryLogger.records;
      expect(records.first.timestamp, at(_raceCommandSecond + 1));
      expect(records.last.timestamp, at(finishedSecond));

      final entries = rig.snapshotLogger.entries;
      expect(entries, hasLength(finishedSecond - _raceCommandSecond));
      expect(entries.first.snapshot.tickTime, at(_raceCommandSecond));
    });
  });

  group('a start scheduled beyond the window', () {
    // The first tick that sees the race (10 s) is exactly the window end,
    // which is exclusive: the race must not start.
    final race = Race.create(
      id: 'replay-expired',
      name: 'Replay lejárt rajt',
      marks: const [fixtureMarkOne],
      scheduledStartAt: at(_raceCommandSecond).subtract(
        const Duration(hours: 3),
      ),
      startPoint: _startPoint,
    );

    test('never starts, guides to the start point, records nothing', () async {
      // Arrange / Act
      await replay(race);

      // Assert - even passing M1 does not round it: the race never ran.
      for (final snapshot in rig.snapshots.sublist(_raceCommandSecond)) {
        expect(snapshot.raceStatus, RaceStatus.notStarted);
        expect(snapshot.raceStartedAt, isNull);
        expect(snapshot.prediction?.mark.name, _startPoint.name);
      }
      expect(rig.telemetryLogger.records, isEmpty);
      expect(rig.snapshotLogger.entries, isEmpty);
    });
  });
}
