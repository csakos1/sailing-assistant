import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.90, longitude: 18.05),
  );

  // Test-helper: a publikus state-machine-en át épített, befejezett
  // verseny — a value objectnek a tartalma közömbös, csak a darabszám
  // és a lista-védelem érdekes.
  Race finishedRace(String id) {
    return Race.create(
      id: id,
      name: 'Verseny $id',
      marks: const [mark],
    ).start(at: DateTime(2026, 5, 1, 10)).finish(at: DateTime(2026, 5, 1, 12));
  }

  group('RaceLogMonth', () {
    test('reports the number of races it holds', () {
      final month = RaceLogMonth(
        month: 5,
        races: [finishedRace('a'), finishedRace('b')],
      );

      expect(month.raceCount, 2);
    });

    test('keeps an unmodifiable defensive copy of the races', () {
      // ARRANGE
      final races = [finishedRace('a')];
      final month = RaceLogMonth(month: 5, races: races);

      // ACT — a hívónál maradt lista bővítése nem szivárog be.
      races.add(finishedRace('b'));

      // ASSERT
      expect(month.raceCount, 1);
      expect(
        () => month.races.add(finishedRace('c')),
        throwsUnsupportedError,
      );
    });

    test('rejects a month number outside 1..12', () {
      expect(
        () => RaceLogMonth(month: 0, races: [finishedRace('a')]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => RaceLogMonth(month: 13, races: [finishedRace('a')]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects an empty month', () {
      expect(
        () => RaceLogMonth(month: 5, races: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
