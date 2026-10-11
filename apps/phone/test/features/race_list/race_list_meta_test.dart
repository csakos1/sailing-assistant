import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_list/race_list_entries.dart';
import 'package:phone/features/race_list/race_list_meta.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();
  const first = Mark(
    sequence: 1,
    name: 'Tihany',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  const second = Mark(
    sequence: 2,
    name: 'Szemes',
    position: Coordinate(latitude: 46.8, longitude: 17.8),
  );
  // A teszt UTC-ben szamol, hogy a gep idozonaja ne szamitson.
  DateTime toUtc(DateTime instant) => instant.toUtc();
  final now = DateTime.utc(2026, 10, 12, 8);

  String metaOf(Race race, {bool isToday = false}) => raceListMetaOf(
    l10n,
    entry: RaceListEntry(race: race, isToday: isToday),
    now: now,
    toLocal: toUtc,
  );

  Race race({List<Mark> marks = const [first, second], DateTime? at}) =>
      Race.create(id: 'r1', name: 'Alfa', marks: marks, scheduledStartAt: at);

  test('shows only the mark count without a scheduled start', () {
    expect(metaOf(race()), '2 bója');
  });

  test('names the markless mode instead of a zero count', () {
    expect(metaOf(race(marks: const [])), 'bója nélkül');
  });

  test('shows today and the start time for a race today', () {
    // ARRANGE
    final today = race(at: DateTime.utc(2026, 10, 12, 9, 5));

    // ACT & ASSERT
    expect(metaOf(today, isToday: true), 'MA · 09:05 · 2 bója');
  });

  test('shows the day in capitals for another day this year', () {
    // ARRANGE
    final later = race(at: DateTime.utc(2026, 11, 3, 10, 30));

    // ACT & ASSERT
    expect(metaOf(later), 'NOV. 3. · 10:30 · 2 bója');
  });

  test('adds the year for another year', () {
    // ARRANGE
    final nextYear = race(
      marks: const [],
      at: DateTime.utc(2027, 1, 3, 11),
    );

    // ACT & ASSERT
    expect(metaOf(nextYear), '2027. JAN. 3. · 11:00 · bója nélkül');
  });

  test('names the targeted mark while the race runs', () {
    // ARRANGE - az elso bojat megkerulte, a masodikra tart.
    final running = race(
      at: DateTime.utc(2026, 10, 12, 9),
    ).start(at: now).roundCurrentMark(at: now);

    // ACT & ASSERT - a rajtido helyett a celzott boja a lenyeg.
    expect(metaOf(running, isToday: true), '2 / 2 · Szemes');
  });

  test('falls back to the plain line for a running markless race', () {
    // ARRANGE
    final running = race(marks: const []).start(at: now);

    // ACT & ASSERT
    expect(metaOf(running), 'bója nélkül');
  });
}
