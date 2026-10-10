import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('InstrumentsRaceChoice', () {
    test('only the calendar day of the choice counts for equality', () {
      // Arrange
      final morning = InstrumentsRaceChoice(
        raceId: 'r1',
        chosenOnLocalDay: DateTime(2026, 7, 30, 8, 15),
      );
      final evening = InstrumentsRaceChoice(
        raceId: 'r1',
        chosenOnLocalDay: DateTime.utc(2026, 7, 30, 21),
      );

      // Assert
      expect(morning, equals(evening));
      expect(morning.hashCode, evening.hashCode);
    });

    test('another day or race differs', () {
      // Arrange
      final base = InstrumentsRaceChoice(
        raceId: 'r1',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );
      final nextDay = InstrumentsRaceChoice(
        raceId: 'r1',
        chosenOnLocalDay: DateTime(2026, 7, 31),
      );
      final otherRace = InstrumentsRaceChoice(
        raceId: 'r2',
        chosenOnLocalDay: DateTime(2026, 7, 30),
      );

      // Assert
      expect(nextDay, isNot(equals(base)));
      expect(otherRace, isNot(equals(base)));
    });

    test('an empty race id is a programming error', () {
      expect(
        () => InstrumentsRaceChoice(
          raceId: '',
          chosenOnLocalDay: DateTime(2026, 7, 30),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
