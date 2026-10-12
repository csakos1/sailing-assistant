import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/instruments_race_chooser.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  final race = Race.create(id: 'race-4', name: 'Esti', marks: const [mark]);

  test('stores the race for the local day, then notifies', () async {
    // Arrange: 23:30 UTC is already the next day in Budapest.
    final events = <String>[];
    InstrumentsRaceChoice? stored;
    final chooser = InstrumentsRaceChooser(
      write: (choice) async {
        stored = choice;
        events.add('write');
      },
      now: () => DateTime.utc(2026, 7, 30, 23, 30),
      toLocal: (instant) => instant.add(const Duration(hours: 2)),
      onChosen: () => events.add('chosen'),
    );

    // Act
    await chooser(race);

    // Assert
    expect(
      stored,
      InstrumentsRaceChoice(
        raceId: 'race-4',
        chosenOnLocalDay: DateTime.utc(2026, 7, 31),
      ),
    );
    expect(events, ['write', 'chosen']);
  });

  test('does not notify when the write fails', () async {
    // Arrange
    var isNotified = false;
    final chooser = InstrumentsRaceChooser(
      write: (_) async => throw StateError('db'),
      now: () => DateTime.utc(2026, 7, 30, 9),
      toLocal: (instant) => instant,
      onChosen: () => isNotified = true,
    );

    // Act & Assert
    await expectLater(chooser(race), throwsStateError);
    expect(isNotified, isFalse);
  });
}
