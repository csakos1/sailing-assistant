import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/instruments_race_selector.dart';

void main() {
  const markA = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  final now = DateTime.utc(2026, 7, 30, 8);
  final scheduled = Race.create(
    id: 'race-1',
    name: 'Tervezett',
    marks: const [markA],
  ).copyWith(scheduledStartAt: DateTime.utc(2026, 7, 30, 9));

  InstrumentsRaceSelector selector({
    List<Race> races = const [],
    Race? selected,
    Map<String, DateTime> lastRecordings = const {},
    InstrumentsRaceChoice? choice,
    bool isChoiceBroken = false,
  }) => InstrumentsRaceSelector(
    readRaces: () async => races,
    readSelectedRace: () => selected,
    readLastRecordingAt: (raceId) async => lastRecordings[raceId],
    readChoice: () async {
      if (isChoiceBroken) throw StateError('broken settings');
      return choice;
    },
    now: () => now,
    // A fixed UTC wall clock keeps the test independent of the machine.
    toLocal: (instant) => instant.toUtc(),
  );

  test("today's scheduled race is the day's race", () async {
    // Act
    final selection = await selector(races: [scheduled]).call();

    // Assert
    expect(selection.dayRace, scheduled);
    expect(selection.races, [scheduled]);
  });

  test('the database copy wins over the selected copy', () async {
    // Arrange: the selection was not refreshed after an edit.
    final stale = scheduled.copyWith(name: 'Regi nev');

    // Act
    final selection = await selector(
      races: [scheduled],
      selected: stale,
    ).call();

    // Assert
    expect(selection.races, [scheduled]);
  });

  test('a selected race missing from the database is added', () async {
    // Arrange: an active race the database has not returned.
    final active = scheduled.start(at: now);

    // Act
    final selection = await selector(selected: active).call();

    // Assert
    expect(selection.dayRace, active);
    expect(selection.races, [active]);
  });

  test('a stale active race uses its last recording', () async {
    // Arrange: started long ago, but recorded a minute ago.
    final active = scheduled.start(at: now.subtract(const Duration(hours: 9)));

    // Act
    final selection = await selector(
      races: [active],
      lastRecordings: {'race-1': now.subtract(const Duration(minutes: 1))},
    ).call();

    // Assert
    expect(selection.dayRace, active);
  });

  test('an unreadable choice is ignored', () async {
    // Act
    final selection = await selector(
      races: [scheduled],
      isChoiceBroken: true,
    ).call();

    // Assert
    expect(selection.dayRace, scheduled);
  });

  test('a race without a start time is free mode', () async {
    // Arrange
    final undated = Race.create(
      id: 'race-2',
      name: 'Datum nelkul',
      marks: const [markA],
    );

    // Act
    final selection = await selector(races: [undated]).call();

    // Assert
    expect(selection.dayRace, isNull);
  });
}
