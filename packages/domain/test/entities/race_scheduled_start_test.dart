import 'package:domain/domain.dart';
import 'package:test/test.dart';

// The scheduled start and the start point of a race (ADR 0055 D1, D2).
void main() {
  const startPosition = Coordinate(latitude: 46.95, longitude: 17.90);
  const startPoint = StartPoint(name: 'Rajtvonal', position: startPosition);
  const markA = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.90, longitude: 18.05),
  );
  const markB = Mark(
    sequence: 2,
    name: 'Z2',
    position: Coordinate(latitude: 46.92, longitude: 18.08),
  );
  final scheduledStartAt = DateTime.utc(2026, 7, 30, 7);
  final startTime = DateTime.utc(2026, 7, 30, 7, 2);
  final finishTime = DateTime.utc(2026, 7, 30, 9);

  Race scheduledRace({List<Mark> marks = const [markA, markB]}) => Race.create(
    id: 'r1',
    name: 'Verseny',
    marks: marks,
    scheduledStartAt: scheduledStartAt,
    startPoint: startPoint,
  );

  group('Race.create with a schedule', () {
    test('keeps the scheduled start and the start point', () {
      // Act
      final race = scheduledRace();

      // Assert
      expect(race.scheduledStartAt, scheduledStartAt);
      expect(race.startPoint, startPoint);
      expect(race.status, RaceStatus.notStarted);
    });

    test('leaves both empty by default', () {
      // Act
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);

      // Assert
      expect(race.scheduledStartAt, isNull);
      expect(race.startPoint, isNull);
    });
  });

  group('state transitions', () {
    test('start, round and finish carry the schedule along', () {
      // Arrange
      final race = scheduledRace();

      // Act
      final started = race.start(at: startTime);
      final rounded = started.roundCurrentMark(at: startTime);
      final finished = rounded.finish(at: finishTime);

      // Assert
      for (final next in [started, rounded, finished]) {
        expect(next.scheduledStartAt, scheduledStartAt);
        expect(next.startPoint, startPoint);
      }
    });

    test('rounding the last mark keeps the schedule', () {
      // Arrange
      final started = scheduledRace(marks: const [markA]).start(at: startTime);

      // Act
      final finished = started.roundCurrentMark(at: finishTime);

      // Assert
      expect(finished.status, RaceStatus.finished);
      expect(finished.scheduledStartAt, scheduledStartAt);
      expect(finished.startPoint, startPoint);
    });
  });

  group('copyWith', () {
    test('keeps the schedule when not given', () {
      // Act
      final renamed = scheduledRace().copyWith(name: 'Uj nev');

      // Assert
      expect(renamed.scheduledStartAt, scheduledStartAt);
      expect(renamed.startPoint, startPoint);
    });

    test('replaces the schedule', () {
      // Arrange
      final later = scheduledStartAt.add(const Duration(hours: 1));
      const otherPoint = StartPoint(name: 'Masik', position: startPosition);

      // Act
      final moved = scheduledRace().copyWith(
        scheduledStartAt: later,
        startPoint: otherPoint,
      );

      // Assert
      expect(moved.scheduledStartAt, later);
      expect(moved.startPoint, otherPoint);
    });

    test('clears the scheduled start and the start point', () {
      // Act
      final cleared = scheduledRace().copyWith(
        clearScheduledStartAt: true,
        clearStartPoint: true,
      );

      // Assert
      expect(cleared.scheduledStartAt, isNull);
      expect(cleared.startPoint, isNull);
    });

    test('a clear flag wins over a new value in the same call', () {
      // Act
      final cleared = scheduledRace().copyWith(
        scheduledStartAt: scheduledStartAt,
        clearScheduledStartAt: true,
      );

      // Assert
      expect(cleared.scheduledStartAt, isNull);
      expect(cleared.startPoint, startPoint);
    });
  });

  group('equality', () {
    test('a different scheduled start makes the races differ', () {
      // Arrange
      final race = scheduledRace();

      // Act
      final moved = race.copyWith(
        scheduledStartAt: scheduledStartAt.add(const Duration(minutes: 5)),
      );

      // Assert
      expect(moved, isNot(equals(race)));
    });

    test('a different start point makes the races differ', () {
      // Arrange
      final race = scheduledRace();

      // Act
      final withoutPoint = race.copyWith(clearStartPoint: true);

      // Assert
      expect(withoutPoint, isNot(equals(race)));
    });
  });

  group('guidanceTargetOrNull', () {
    test('before the start it is the start point', () {
      // Act
      final target = scheduledRace().guidanceTargetOrNull;

      // Assert
      expect(target, startPoint.asGuidanceMark());
    });

    test('before the start without a start point it is the first mark', () {
      // Act
      final target = scheduledRace()
          .copyWith(
            clearStartPoint: true,
          )
          .guidanceTargetOrNull;

      // Assert
      expect(target, markA);
    });

    test('after the start it is the active mark, not the start point', () {
      // Act
      final target = scheduledRace().start(at: startTime).guidanceTargetOrNull;

      // Assert
      expect(target, markA);
    });

    test('it follows the active mark after a rounding', () {
      // Arrange
      final started = scheduledRace().start(at: startTime);

      // Act
      final target = started
          .roundCurrentMark(
            at: startTime,
          )
          .guidanceTargetOrNull;

      // Assert
      expect(target, markB);
    });

    test('a finished race has no target', () {
      // Arrange
      final started = scheduledRace().start(at: startTime);

      // Act
      final target = started.finish(at: finishTime).guidanceTargetOrNull;

      // Assert
      expect(target, isNull);
    });

    test('a race without marks leads to its start point', () {
      // Act
      final target = scheduledRace(marks: const []).guidanceTargetOrNull;

      // Assert
      expect(target, startPoint.asGuidanceMark());
    });

    test('a race without marks and start point has no target', () {
      // Act
      final target = Race.create(
        id: 'r1',
        name: 'Tura',
        marks: const [],
      ).guidanceTargetOrNull;

      // Assert
      expect(target, isNull);
    });

    test('a started race without marks has no target', () {
      // Act
      final target = scheduledRace(
        marks: const [],
      ).start(at: startTime).guidanceTargetOrNull;

      // Assert
      expect(target, isNull);
    });
  });

  group('guidanceNextOrNull', () {
    test('before the start with a start point it is the first mark', () {
      // Act
      final next = scheduledRace().guidanceNextOrNull;

      // Assert
      expect(next, markA);
    });

    test('before the start without a start point it is the second mark', () {
      // Act
      final next = scheduledRace()
          .copyWith(
            clearStartPoint: true,
          )
          .guidanceNextOrNull;

      // Assert
      expect(next, markB);
    });

    test('a single-mark race without a start point has no next leg', () {
      // Act
      final next = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).guidanceNextOrNull;

      // Assert
      expect(next, isNull);
    });

    test('after the start it is the next mark', () {
      // Act
      final next = scheduledRace().start(at: startTime).guidanceNextOrNull;

      // Assert
      expect(next, markB);
    });

    test('on the last mark there is no next leg', () {
      // Arrange
      final started = scheduledRace().start(at: startTime);

      // Act
      final next = started.roundCurrentMark(at: startTime).guidanceNextOrNull;

      // Assert
      expect(next, isNull);
    });

    test('a finished race has no next leg', () {
      // Arrange
      final started = scheduledRace().start(at: startTime);

      // Act
      final next = started.finish(at: finishTime).guidanceNextOrNull;

      // Assert
      expect(next, isNull);
    });

    test('a race without marks has no next leg even with a start point', () {
      // Act
      final next = scheduledRace(marks: const []).guidanceNextOrNull;

      // Assert
      expect(next, isNull);
    });
  });

  group('the existing getters', () {
    test('activeMarkOrNull ignores the start point', () {
      // Act
      final active = scheduledRace().activeMarkOrNull;

      // Assert
      expect(active, markA);
    });

    test('nextMarkOrNull ignores the start point', () {
      // Act
      final next = scheduledRace().nextMarkOrNull;

      // Assert
      expect(next, markB);
    });
  });
}
