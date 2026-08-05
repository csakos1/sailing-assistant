import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_log_provider.dart';
import 'package:phone/providers/race_log_year_provider.dart';

void main() {
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.90, longitude: 18.05),
  );

  // Test-helper: egy ev egyetlen honappal es egyetlen versennyel. A
  // tartalom kozombos, csak az evszam szamit a feloldasnal.
  RaceLogYear logYear(int year) {
    final race = Race.create(
      id: 'race-$year',
      name: 'Verseny $year',
      marks: const [mark],
    ).start(at: DateTime(year, 5, 1, 10)).finish(at: DateTime(year, 5, 1, 12));

    return RaceLogYear(
      year: year,
      months: [
        RaceLogMonth(month: 5, races: [race]),
      ],
    );
  }

  // A raceLogProvider-t irjuk felul, nem a raceListProvider-t: a
  // feloldas a mar felepitett szerkezet folott dolgozik, a stream
  // mockolasa itt csak zajt adna.
  ProviderContainer containerFor(AsyncValue<List<RaceLogYear>> log) {
    final container = ProviderContainer(
      overrides: [raceLogProvider.overrideWith((ref) => log)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('raceLogSelectedYearProvider', () {
    test('defaults to the newest year when nothing is selected', () {
      // ARRANGE
      final container = containerFor(
        AsyncValue.data([logYear(2026), logYear(2024)]),
      );

      // ACT & ASSERT
      expect(container.read(raceLogSelectedYearProvider)?.year, 2026);
    });

    test('returns the selected year while it exists in the log', () {
      // ARRANGE
      final container = containerFor(
        AsyncValue.data([logYear(2026), logYear(2024)]),
      );

      // ACT
      container.read(raceLogYearSelectionProvider.notifier).state = 2024;

      // ASSERT
      expect(container.read(raceLogSelectedYearProvider)?.year, 2024);
    });

    test('falls back to the newest year when the selection is gone', () {
      // ARRANGE - a valasztott ev utolso versenyet torolhettek, igy az
      // ev eltunt a naplobol.
      final container = containerFor(
        AsyncValue.data([logYear(2026), logYear(2024)]),
      );
      container.read(raceLogYearSelectionProvider.notifier).state = 2019;

      // ACT & ASSERT
      expect(container.read(raceLogSelectedYearProvider)?.year, 2026);
    });

    test('returns null for an empty log', () {
      final container = containerFor(
        const AsyncValue<List<RaceLogYear>>.data(<RaceLogYear>[]),
      );

      expect(container.read(raceLogSelectedYearProvider), isNull);
    });

    test('returns null while the log is still loading', () {
      final container = containerFor(
        const AsyncValue<List<RaceLogYear>>.loading(),
      );

      expect(container.read(raceLogSelectedYearProvider), isNull);
    });
  });

  group('raceLogYearSelectionProvider', () {
    test('starts empty so the default year wins on first open', () {
      final container = containerFor(AsyncValue.data([logYear(2026)]));

      expect(container.read(raceLogYearSelectionProvider), isNull);
    });
  });
}
