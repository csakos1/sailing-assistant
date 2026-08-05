import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.90, longitude: 18.05),
  );

  Race finishedRace(String id) {
    return Race.create(
      id: id,
      name: 'Verseny $id',
      marks: const [mark],
    ).start(at: DateTime(2026, 5, 1, 10)).finish(at: DateTime(2026, 5, 1, 12));
  }

  RaceLogMonth monthWith(int month, int raceCount) {
    return RaceLogMonth(
      month: month,
      races: [
        for (var index = 0; index < raceCount; index++)
          finishedRace('$month-$index'),
      ],
    );
  }

  group('RaceLogYear', () {
    test('sums the race counts of all its months', () {
      final year = RaceLogYear(
        year: 2026,
        months: [monthWith(8, 3), monthWith(5, 2)],
      );

      expect(year.raceCount, 5);
    });

    test('keeps an unmodifiable defensive copy of the months', () {
      // ARRANGE
      final months = [monthWith(5, 1)];
      final year = RaceLogYear(year: 2026, months: months);

      // ACT — a hívónál maradt lista bővítése nem szivárog be.
      months.add(monthWith(8, 1));

      // ASSERT
      expect(year.months, hasLength(1));
      expect(
        () => year.months.add(monthWith(9, 1)),
        throwsUnsupportedError,
      );
    });

    test('rejects an empty year', () {
      expect(
        () => RaceLogYear(year: 2026, months: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
