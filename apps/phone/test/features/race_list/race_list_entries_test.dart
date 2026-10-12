import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_list/race_list_entries.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 18.05),
  );
  // A teszt UTC-ben szamol, hogy a gep idozonaja ne szamitson.
  DateTime toUtc(DateTime instant) => instant.toUtc();
  final now = DateTime.utc(2026, 10, 12, 8);

  Race race(String id, {DateTime? at}) => Race.create(
    id: id,
    name: id,
    marks: const [mark],
    scheduledStartAt: at,
  );

  List<String> idsOf(List<RaceListEntry> entries) => [
    for (final entry in entries) entry.race.id,
  ];

  List<RaceListEntry> entriesOf(List<Race> races) =>
      raceListEntriesOf(races: races, now: now, toLocal: toUtc);

  test('puts the running race first, then by scheduled start', () {
    // ARRANGE
    final races = [
      race('undated'),
      race('later', at: DateTime.utc(2026, 10, 14, 9)),
      race('running').start(at: now),
      race('sooner', at: DateTime.utc(2026, 10, 12, 9)),
    ];

    // ACT
    final entries = entriesOf(races);

    // ASSERT
    expect(idsOf(entries), ['running', 'sooner', 'later', 'undated']);
  });

  test('puts a missed past-day race after the upcoming ones', () {
    // ARRANGE - a tegnapi, el nem inditott verseny ne a mai ele keruljon.
    final races = [
      race('undated'),
      race('missed', at: DateTime.utc(2026, 10, 11, 9)),
      race('today', at: DateTime.utc(2026, 10, 12, 18)),
      race('earlier today', at: DateTime.utc(2026, 10, 12, 6)),
    ];

    // ACT
    final entries = entriesOf(races);

    // ASSERT - a ma korabban esedekes is a mai csoport resze.
    expect(idsOf(entries), ['earlier today', 'today', 'missed', 'undated']);
  });

  test('keeps the input order for equal start times', () {
    // ARRANGE
    final at = DateTime.utc(2026, 10, 13, 10);
    final races = [race('b', at: at), race('a', at: at), race('c', at: at)];

    // ACT
    final entries = entriesOf(races);

    // ASSERT - a List.sort nem stabil, ezert ez a teszt tud bukni.
    expect(idsOf(entries), ['b', 'a', 'c']);
  });

  test('keeps the input order of the undated races', () {
    // ARRANGE
    final races = [race('z'), race('x'), race('y')];

    // ACT & ASSERT
    expect(idsOf(entriesOf(races)), ['z', 'x', 'y']);
  });

  test('leaves the finished races out', () {
    // ARRANGE
    final races = [
      race('done').start(at: now).finish(at: now),
      race('open'),
    ];

    // ACT & ASSERT
    expect(idsOf(entriesOf(races)), ['open']);
  });

  test('marks a race scheduled for the local today', () {
    // ARRANGE
    final races = [
      race('today', at: DateTime.utc(2026, 10, 12, 23, 30)),
      race('tomorrow', at: DateTime.utc(2026, 10, 13)),
      race('yesterday', at: DateTime.utc(2026, 10, 11, 23, 59)),
      race('undated'),
    ];

    // ACT
    final entries = entriesOf(races);

    // ASSERT
    final isTodayById = {
      for (final entry in entries) entry.race.id: entry.isToday,
    };
    expect(isTodayById, {
      'yesterday': false,
      'today': true,
      'tomorrow': false,
      'undated': false,
    });
  });

  test('decides the day by the local wall clock', () {
    // ARRANGE - UTC szerint mar holnap, egy -2 oras ido szerint meg ma.
    final races = [race('late', at: DateTime.utc(2026, 10, 13, 1))];
    DateTime minusTwoHours(DateTime instant) =>
        instant.toUtc().subtract(const Duration(hours: 2));

    // ACT
    final entries = raceListEntriesOf(
      races: races,
      now: now,
      toLocal: minusTwoHours,
    );

    // ASSERT
    expect(entries.single.isToday, isTrue);
  });
}
