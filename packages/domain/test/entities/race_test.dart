import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Közös fixtúrák. Balaton-közeli koordináták (Siófok környéke), nem
  // valódi bóya-pozíciók — csak strukturális helyőrzők a tesztekhez.
  const positionA = Coordinate(latitude: 46.90, longitude: 18.05);
  const positionB = Coordinate(latitude: 46.92, longitude: 18.08);
  const positionC = Coordinate(latitude: 46.95, longitude: 18.12);

  const markA = Mark(sequence: 1, name: 'Z1', position: positionA);
  const markB = Mark(sequence: 2, name: 'Z2', position: positionB);
  const markC = Mark(sequence: 3, name: 'Z3', position: positionC);

  final startTime = DateTime.utc(2025, 6, 1, 10);
  final roundTime = DateTime.utc(2025, 6, 1, 10, 15);
  final finishTime = DateTime.utc(2025, 6, 1, 11);

  group('Race.create', () {
    test('notStarted state-tel, index 0-án, üres időbélyegekkel', () {
      // ARRANGE
      const marks = <Mark>[markA, markB];

      // ACT
      final race = Race.create(id: 'r1', name: 'Verseny', marks: marks);

      // ASSERT
      expect(race.status, RaceStatus.notStarted);
      expect(race.activeMarkIndex, 0);
      expect(race.startedAt, isNull);
      expect(race.finishedAt, isNull);
      expect(race.marks, marks);
    });

    test('a marks lista immutable a Race-en belül', () {
      // ARRANGE
      final mutableMarks = <Mark>[markA, markB];
      final race = Race.create(
        id: 'r1',
        name: 'Verseny',
        marks: mutableMarks,
      );

      // ACT & ASSERT — defensive copy: a Race-en belüli lista nem írható.
      expect(() => race.marks.add(markC), throwsUnsupportedError);
    });
  });

  group('konstruktor invariáns assertek', () {
    test('üres id → AssertionError', () {
      expect(
        () => Race.create(id: '', name: 'Verseny', marks: const [markA]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('üres név → AssertionError', () {
      expect(
        () => Race.create(id: 'r1', name: '', marks: const [markA]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('üres marks lista → AssertionError', () {
      expect(
        () => Race.create(id: 'r1', name: 'Verseny', marks: const []),
        throwsA(isA<AssertionError>()),
      );
    });

    test('notStarted + startedAt érték → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA],
          status: RaceStatus.notStarted,
          activeMarkIndex: 0,
          startedAt: startTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('notStarted + activeMarkIndex != 0 → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA, markB],
          status: RaceStatus.notStarted,
          activeMarkIndex: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('active + startedAt == null → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA],
          status: RaceStatus.active,
          activeMarkIndex: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('active + finishedAt érték → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA],
          status: RaceStatus.active,
          activeMarkIndex: 0,
          startedAt: startTime,
          finishedAt: finishTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('active + activeMarkIndex == marks.length → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA, markB],
          status: RaceStatus.active,
          activeMarkIndex: 2,
          startedAt: startTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('finished + finishedAt == null → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA],
          status: RaceStatus.finished,
          activeMarkIndex: 1,
          startedAt: startTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('finished + activeMarkIndex != marks.length → AssertionError', () {
      expect(
        () => Race(
          id: 'r1',
          name: 'Verseny',
          marks: const [markA, markB],
          status: RaceStatus.finished,
          activeMarkIndex: 1,
          startedAt: startTime,
          finishedAt: finishTime,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('equality (Equatable)', () {
    test('azonos mezők → egyenlő', () {
      // ARRANGE & ACT
      final race1 = Race.create(
        id: 'r1',
        name: 'Verseny',
        marks: const [markA],
      );
      final race2 = Race.create(
        id: 'r1',
        name: 'Verseny',
        marks: const [markA],
      );

      // ASSERT
      expect(race1, equals(race2));
      expect(race1.hashCode, race2.hashCode);
    });

    test('különböző id → nem egyenlő', () {
      final race1 = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      final race2 = Race.create(id: 'r2', name: 'V', marks: const [markA]);
      expect(race1, isNot(equals(race2)));
    });

    test('különböző marks → nem egyenlő', () {
      final race1 = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      final race2 = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA, markB],
      );
      expect(race1, isNot(equals(race2)));
    });

    test('különböző status → nem egyenlő', () {
      final race1 = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      final race2 = race1.start(at: startTime);
      expect(race1, isNot(equals(race2)));
    });
  });

  group('copyWith', () {
    test('egy mező változik, többi marad', () {
      // ARRANGE
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);

      // ACT
      final renamed = race.copyWith(name: 'Új név');

      // ASSERT
      expect(renamed.name, 'Új név');
      expect(renamed.id, race.id);
      expect(renamed.marks, race.marks);
      expect(renamed.status, race.status);
    });

    test('null paraméter nem változtat', () {
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      final copy = race.copyWith();
      expect(copy, equals(race));
    });
  });

  group('start()', () {
    test('notStarted → active, startedAt beáll', () {
      // ARRANGE
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);

      // ACT
      final started = race.start(at: startTime);

      // ASSERT
      expect(started.status, RaceStatus.active);
      expect(started.startedAt, startTime);
      expect(started.activeMarkIndex, 0);
      expect(started.finishedAt, isNull);
    });

    test('active állapotból hívva → AssertionError', () {
      final active = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).start(at: startTime);
      expect(
        () => active.start(at: startTime),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('roundCurrentMark()', () {
    test('nem-utolsó bóya: index lépik, mark rounded, status active marad', () {
      // ARRANGE
      final race = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA, markB],
      ).start(at: startTime);

      // ACT
      final after = race.roundCurrentMark(at: roundTime);

      // ASSERT
      expect(after.activeMarkIndex, 1);
      expect(after.status, RaceStatus.active);
      expect(after.finishedAt, isNull);
      expect(after.marks[0].roundedAt, roundTime);
      expect(after.marks[1].roundedAt, isNull);
    });

    test('utolsó bóya: state finished, finishedAt beáll, index = length', () {
      // ARRANGE
      final race = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).start(at: startTime);

      // ACT
      final after = race.roundCurrentMark(at: finishTime);

      // ASSERT
      expect(after.status, RaceStatus.finished);
      expect(after.activeMarkIndex, 1);
      expect(after.finishedAt, finishTime);
      expect(after.marks[0].roundedAt, finishTime);
    });

    test('notStarted állapotból hívva → AssertionError', () {
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      expect(
        () => race.roundCurrentMark(at: roundTime),
        throwsA(isA<AssertionError>()),
      );
    });

    test('finished állapotból hívva → AssertionError', () {
      final done = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).start(at: startTime).roundCurrentMark(at: finishTime);
      expect(
        () => done.roundCurrentMark(at: finishTime),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('finish()', () {
    test('active → finished, finishedAt beáll, index = length', () {
      // ARRANGE
      final race = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA, markB],
      ).start(at: startTime);

      // ACT
      final aborted = race.finish(at: finishTime);

      // ASSERT
      expect(aborted.status, RaceStatus.finished);
      expect(aborted.finishedAt, finishTime);
      expect(aborted.activeMarkIndex, 2);
      // A bólyák nem lettek rounded — DNF szemantika.
      expect(aborted.marks[0].roundedAt, isNull);
      expect(aborted.marks[1].roundedAt, isNull);
    });

    test('notStarted állapotból hívva → AssertionError', () {
      final race = Race.create(id: 'r1', name: 'V', marks: const [markA]);
      expect(
        () => race.finish(at: finishTime),
        throwsA(isA<AssertionError>()),
      );
    });

    test('finished állapotból hívva → AssertionError', () {
      final done = Race.create(
        id: 'r1',
        name: 'V',
        marks: const [markA],
      ).start(at: startTime).roundCurrentMark(at: finishTime);
      expect(
        () => done.finish(at: finishTime),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('toString()', () {
    test('tartalmazza a kulcs-mezőket', () {
      final race = Race.create(id: 'r1', name: 'Verseny', marks: const [markA]);
      final s = race.toString();
      expect(s, contains('r1'));
      expect(s, contains('Verseny'));
      expect(s, contains('notStarted'));
    });
  });
}
