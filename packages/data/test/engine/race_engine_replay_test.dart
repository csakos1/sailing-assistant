import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'replay_rig.dart';

// Replay test of the whole engine life cycle (ADR 0054 E4) on the recorded
// synthetic fixture tools/sample_logs/moving_mark_rounding.nmea: the boat
// starts ~150 m south of M1, passes it at ~8 m and bears away towards M2.
// Every second of the log is fed through the real NmeaEventPipeline into
// the engine, then one tick follows - the tick sees the whole second, as
// on the boat.

// The seconds of the replay at which the "host" sends its commands.
const _raceCommandSecond = 10;
const _startCommandSecond = 20;

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

  group('single-mark race', () {
    final race = Race.create(
      id: 'replay-single',
      name: 'Replay egy bója',
      marks: const [fixtureMarkOne],
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
          .map(distanceToMarkMeters)
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
      marks: const [fixtureMarkOne, fixtureMarkTwo],
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
        distanceToMarkMeters(activeSnapshots.last),
        lessThan(distanceToMarkMeters(activeSnapshots[stepIndex])),
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
