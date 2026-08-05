import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const buildRaceLog = BuildRaceLog();

  // Közös fixtúra: a naplónak a pálya közömbös, egyetlen bója elég.
  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.90, longitude: 18.05),
  );

  // Test-helper: befejezett verseny a publikus state-machine-en át
  // (create -> start -> finish), hogy a Race invariánsát biztosan ne
  // sértsük meg. A rajt fix két órával a befejezés előtt van.
  Race finishedRace(String id, DateTime finishedAt) {
    return Race.create(id: id, name: 'Verseny $id', marks: const [mark])
        .start(at: finishedAt.subtract(const Duration(hours: 2)))
        .finish(at: finishedAt);
  }

  group('BuildRaceLog filtering', () {
    test('returns an empty log for an empty race list', () {
      expect(buildRaceLog(const []), isEmpty);
    });

    test('ignores races that have not finished yet', () {
      // ARRANGE
      final notStarted = Race.create(
        id: 'r1',
        name: 'Elso',
        marks: const [mark],
      );
      final active = Race.create(
        id: 'r2',
        name: 'Masodik',
        marks: const [mark],
      ).start(at: DateTime(2026, 5, 1, 10));

      // ACT
      final log = buildRaceLog([notStarted, active]);

      // ASSERT
      expect(log, isEmpty);
    });

    test('keeps only the finished races from a mixed list', () {
      // ARRANGE
      final active = Race.create(
        id: 'pending',
        name: 'Fut',
        marks: const [mark],
      ).start(at: DateTime(2026, 5, 1, 10));
      final done = finishedRace('done', DateTime(2026, 5, 3, 14));

      // ACT
      final log = buildRaceLog([active, done]);

      // ASSERT
      expect(log.single.year, 2026);
      expect(log.single.months.single.races.single.id, 'done');
    });
  });

  group('BuildRaceLog grouping and ordering', () {
    test('orders years and months newest first', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('a', DateTime(2024, 7, 10, 12)),
        finishedRace('b', DateTime(2026, 3, 2, 12)),
        finishedRace('c', DateTime(2026, 9, 18, 12)),
      ]);

      // ASSERT
      expect(log.map((year) => year.year), [2026, 2024]);
      expect(log.first.months.map((month) => month.month), [9, 3]);
      expect(log.last.months.map((month) => month.month), [7]);
    });

    test('orders races inside a month by finish time, newest first', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('early', DateTime(2026, 5, 2, 9)),
        finishedRace('late', DateTime(2026, 5, 28, 17)),
        finishedRace('middle', DateTime(2026, 5, 15, 13)),
      ]);

      // ASSERT
      final races = log.single.months.single.races;
      expect(races.map((race) => race.id), ['late', 'middle', 'early']);
    });

    test('breaks ties on the race id so the order is deterministic', () {
      // ARRANGE — a List.sort nem stabil, ezért két azonos időbélyegű
      // verseny sorrendjét az id dönti el, futásról futásra ugyanúgy.
      final sameInstant = DateTime(2026, 6, 6, 12);

      // ACT
      final log = buildRaceLog([
        finishedRace('c', sameInstant),
        finishedRace('a', sameInstant),
        finishedRace('b', sameInstant),
      ]);

      // ASSERT
      final races = log.single.months.single.races;
      expect(races.map((race) => race.id), ['a', 'b', 'c']);
    });

    test('keeps two races finished on the same day in the same month', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('morning', DateTime(2026, 6, 6, 9, 30)),
        finishedRace('evening', DateTime(2026, 6, 6, 18, 15)),
      ]);

      // ASSERT
      final month = log.single.months.single;
      expect(month.month, 6);
      expect(month.races.map((race) => race.id), ['evening', 'morning']);
    });

    test('does not create months without finished races', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('a', DateTime(2026, 2, 1, 12)),
        finishedRace('b', DateTime(2026, 11, 1, 12)),
      ]);

      // ASSERT — február és november között nincs üres hónap-tétel.
      expect(log.single.months.map((month) => month.month), [11, 2]);
    });

    test('separates two years that share a month number', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('old', DateTime(2025, 8, 12, 12)),
        finishedRace('new', DateTime(2026, 8, 12, 12)),
      ]);

      // ASSERT
      expect(log.map((year) => year.year), [2026, 2025]);
      expect(log.first.months.single.races.single.id, 'new');
      expect(log.last.months.single.races.single.id, 'old');
    });
  });

  group('BuildRaceLog local time semantics', () {
    test('groups by the local calendar rather than the UTC one', () {
      // ARRANGE — a teszt-futtató időzónája nem rögzített (fejlesztői
      // gép: Europe/Budapest, GitHub Actions: UTC), ezért a várakozást
      // a toLocal()-ból származtatjuk. A szerződés az, hogy a
      // csoportosító kulcs a HELYI naptár éve és hónapja (D32).
      final instant = DateTime.utc(2025, 12, 31, 23, 30);
      final local = instant.toLocal();

      // ACT
      final log = buildRaceLog([finishedRace('r1', instant)]);

      // ASSERT
      expect(log.single.year, local.year);
      expect(log.single.months.single.month, local.month);

      // Pozitív eltolású zónában ez már a következő év januárja: ott a
      // UTC-kulcs használata is kimutatható hibaként. UTC-n futó CI-n a
      // két ág egybeesik, ezért ott a fenti állítás az érdemi.
      if (local.year != instant.year) {
        expect(log.single.year, isNot(instant.year));
      }
    });

    test('places a race on the local side of a month boundary', () {
      // ARRANGE
      final instant = DateTime.utc(2026, 4, 30, 23, 45);
      final local = instant.toLocal();

      // ACT
      final log = buildRaceLog([finishedRace('r1', instant)]);

      // ASSERT
      expect(log.single.months.single.month, local.month);
    });
  });

  group('BuildRaceLog structure guarantees', () {
    test('counts races per month and per year', () {
      // ARRANGE & ACT
      final log = buildRaceLog([
        finishedRace('a', DateTime(2026, 5, 2, 9)),
        finishedRace('b', DateTime(2026, 5, 9, 9)),
        finishedRace('c', DateTime(2026, 8, 9, 9)),
      ]);

      // ASSERT
      expect(log.single.raceCount, 3);
      expect(log.single.months.map((month) => month.raceCount), [1, 2]);
    });

    test('returns unmodifiable years, months and race lists', () {
      // ARRANGE
      final log = buildRaceLog([
        finishedRace('a', DateTime(2026, 5, 2, 9)),
      ]);
      final year = log.single;
      final month = year.months.single;

      // ACT & ASSERT — a napló szerkezete kívülről nem állítható.
      expect(() => log.add(year), throwsUnsupportedError);
      expect(() => year.months.add(month), throwsUnsupportedError);
      expect(
        () => month.races.add(month.races.first),
        throwsUnsupportedError,
      );
    });
  });
}
