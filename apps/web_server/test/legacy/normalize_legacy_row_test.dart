import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_cell.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';
import 'package:web_server/src/legacy/legacy_row_rejection.dart';
import 'package:web_server/src/legacy/normalize_legacy_row.dart';

import 'legacy_rows.dart';

LegacyRace _accepted(Result<LegacyRace, LegacyRowRejection> result) =>
    switch (result) {
      Ok(:final value) => value,
      Err(:final error) => fail('rejected: ${error.problems}'),
    };

LegacyRowRejection _rejected(Result<LegacyRace, LegacyRowRejection> result) =>
    switch (result) {
      Ok() => fail('accepted'),
      Err(:final error) => error,
    };

void main() {
  group('normalizeLegacyRow', () {
    test('reads a complete row of the 2021 season', () {
      // ARRANGE: row 4 of the real sheet
      final row = legacyRow(
        rowNumber: 4,
        date: DateTime.utc(2021, 6, 5),
        name: ' Mihálkovics Emlékverseny I. futam ',
        cells: {
          'YS szám': const LegacyNumber(73),
          'Oszt. helyezés': const LegacyNumber(9),
          'Abszolút helyezés': const LegacyNumber(2),
          'Rajt': wallClock(2021, 6, 5, 10),
          'Befutás': wallClock(2021, 6, 5, 14, 22, 19),
          'Táv (NM)': const LegacyNumber(20.2),
          'Max seb. (kn)': const LegacyNumber(9.4),
          'Átl. szél (kn)': const LegacyNumber(4.8),
          'Max szél (kn)': const LegacyNumber(14.1),
          'Szélirány': const LegacyText('Ny'),
          'Díj / megjegyzés': const LegacyText('-'),
          'Telemetria forrása': const LegacyText('mért'),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.rowNumber, 4);
      expect(race.name, 'Mihálkovics Emlékverseny I. futam');
      expect(race.date, CalendarDate.tryParse('2021-06-05'));
      expect(race.result.classPlace, const FinishPlace(9));
      expect(race.result.overallPlace, const FinishPlace(2));
      expect(race.result.ysNumberHundredths, 7300);
      expect(race.result.officialStart, DateTime.utc(2021, 6, 5, 8));
      expect(race.result.officialFinish, DateTime.utc(2021, 6, 5, 12, 22, 19));
      expect(race.result.prize, isNull);
      expect(race.manualRace.distanceMeters, closeTo(37410.4, 1e-6));
      expect(race.manualRace.maxSpeedMps, closeTo(4.8358, 1e-4));
      expect(race.manualRace.avgWindMps, closeTo(2.4693, 1e-4));
      expect(race.manualRace.windPoint, CompassPoint.west);
      expect(race.twoDayResults, isNull);
    });

    test('rounds a decimal YS number to hundredths', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 62,
        cells: {'YS szám': const LegacyNumber(75.9)},
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.ysNumberHundredths, 7590);
    });

    test('takes the absolute value of a negative placing with a note', () {
      // ARRANGE: rows 52 and 59 mark the class placing negative
      final row = legacyRow(
        rowNumber: 52,
        cells: {'Oszt. helyezés': const LegacyNumber(-3)},
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.classPlace, const FinishPlace(3));
      expect(race.notes, hasLength(1));
    });

    test('reads a dotted and a slashed placing', () {
      // ARRANGE: row 70 holds "8. / 6."
      final row = legacyRow(
        rowNumber: 70,
        cells: {
          'Abszolút helyezés': const LegacyText('20.'),
          'Egytestű helyezés': const LegacyText('8. / 6.'),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.overallPlace, const FinishPlace(20));
      expect(race.result.monohullPlace, const FinishPlace(8));
      expect(race.notes, hasLength(1));
    });

    test('reads DNF, DNC and DSQ placings', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 10,
        cells: {
          'Oszt. helyezés': const LegacyText('dnc'),
          'Abszolút helyezés': const LegacyText('DNF'),
          'Egytestű helyezés': const LegacyText(' DSQ '),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.classPlace, const Dnf());
      expect(race.result.overallPlace, const Dnf());
      expect(race.result.monohullPlace, const Dsq());
    });

    test('turns a DNF finish into DNF on all three placings', () {
      // ARRANGE: row 66, BAHART Alsoors 2026
      final row = legacyRow(
        rowNumber: 66,
        date: DateTime.utc(2026, 6, 27),
        cells: {
          'Mezőny (hajó)': const LegacyNumber(56),
          'Rajt': wallClock(2026, 6, 27, 11),
          'Befutás': const LegacyText('DNF'),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.classPlace, const Dnf());
      expect(race.result.overallPlace, const Dnf());
      expect(race.result.monohullPlace, const Dnf());
      expect(race.result.overallFleetSize, 56);
      expect(race.result.officialStart, DateTime.utc(2026, 6, 27, 9));
      expect(race.result.officialFinish, isNull);
    });

    test('reads the text time formats of the 2026 rows', () {
      // ARRANGE: rows 51, 67 and 70
      final row = legacyRow(
        rowNumber: 70,
        date: DateTime.utc(2026, 7, 30),
        cells: {
          'Rajt': const LegacyText('2026.07.30. 9:00'),
          'Befutás': const LegacyText('2026.07.31. 08:35'),
        },
      );
      final spaced = legacyRow(
        rowNumber: 51,
        date: DateTime.utc(2025, 5, 25),
        cells: {'Rajt': const LegacyText('2025.05.25 12:00')},
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));
      final spacedRace = _accepted(normalizeLegacyRow(spaced));

      // ASSERT
      expect(race.result.officialStart, DateTime.utc(2026, 7, 30, 7));
      expect(race.result.officialFinish, DateTime.utc(2026, 7, 31, 6, 35));
      expect(spacedRace.result.officialStart, DateTime.utc(2025, 5, 25, 10));
    });

    test('rounds a time cell to the nearest second', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 3,
        date: DateTime.utc(2021, 5, 15),
        cells: {
          'Befutás': LegacyDateTime(DateTime.utc(2021, 5, 15, 15, 47, 58, 840)),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.officialFinish, DateTime.utc(2021, 5, 15, 13, 47, 59));
    });

    test('splits a two-day row into the days', () {
      // ARRANGE: row 64, Mihalkovics 2026
      final row = legacyRow(
        rowNumber: 64,
        date: DateTime.utc(2026, 6, 13),
        cells: {
          'YS szám': const LegacyNumber(75.9),
          'Oszt. helyezés': const LegacyNumber(1),
          'Abszolút helyezés': const LegacyText('19.'),
          'Abszolút 2. nap': const LegacyText('1.'),
          'Egytestű helyezés': const LegacyText('13.'),
          'Egytestű 2. nap': const LegacyText('1.'),
          'Mezőny (hajó)': const LegacyNumber(181),
          'Rajt': wallClock(2026, 6, 13, 10),
          'Befutás': wallClock(2026, 6, 14, 12, 27, 37),
          'Díj / megjegyzés': const LegacyText('érmek'),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      final days = race.twoDayResults;
      expect(
        days?.first,
        const RaceResultInput(
          overallPlace: FinishPlace(19),
          overallFleetSize: 181,
          monohullPlace: FinishPlace(13),
          ysNumberHundredths: 7590,
        ),
      );
      expect(
        days?.second,
        const RaceResultInput(
          classPlace: FinishPlace(1),
          overallPlace: FinishPlace(1),
          overallFleetSize: 181,
          monohullPlace: FinishPlace(1),
          ysNumberHundredths: 7590,
          prize: 'érmek',
        ),
      );
    });

    test('drops the official times that span both days of a row', () {
      // ARRANGE: the whole-row result is used when the row is not split
      final row = legacyRow(
        rowNumber: 64,
        date: DateTime.utc(2026, 6, 13),
        cells: {
          'Abszolút helyezés': const LegacyText('19.'),
          'Abszolút 2. nap': const LegacyText('1.'),
          'Rajt': wallClock(2026, 6, 13, 10),
          'Befutás': wallClock(2026, 6, 14, 12, 27, 37),
        },
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.result.officialStart, isNull);
      expect(race.result.officialFinish, isNull);
      expect(race.result.overallPlace, const FinishPlace(19));
    });

    test('keeps a DNF row one-day when the day-two columns are empty', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 66,
        cells: {'Befutás': const LegacyText('DNF')},
      );

      // ACT
      final race = _accepted(normalizeLegacyRow(row));

      // ASSERT
      expect(race.twoDayResults, isNull);
    });

    test('rejects a row with an unreadable time and an unknown direction', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 9,
        cells: {
          'Rajt': const LegacyText('reggel'),
          'Szélirány': const LegacyText('ÉKK'),
        },
      );

      // ACT
      final rejection = _rejected(normalizeLegacyRow(row));

      // ASSERT: every problem of the row, not only the first
      expect(rejection.rowNumber, 9);
      expect(rejection.name, 'Teszt verseny');
      expect(
        rejection.problems.map((problem) => (problem.column, problem.kind)),
        unorderedEquals([
          ('Rajt', LegacyProblemKind.unreadable),
          ('Szélirány', LegacyProblemKind.unreadable),
        ]),
      );
    });

    test('rejects a row without a name', () {
      // ARRANGE
      final row = legacyRow(rowNumber: 5, name: '   ');

      // ACT
      final rejection = _rejected(normalizeLegacyRow(row));

      // ASSERT
      expect(rejection.problems.single.column, 'Verseny');
      expect(rejection.problems.single.kind, LegacyProblemKind.missing);
    });

    test('rejects a placing beyond the fleet size', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 6,
        cells: {
          'Abszolút helyezés': const LegacyNumber(12),
          'Mezőny (hajó)': const LegacyNumber(10),
        },
      );

      // ACT
      final rejection = _rejected(normalizeLegacyRow(row));

      // ASSERT
      expect(rejection.problems.single.kind, LegacyProblemKind.invalid);
      expect(rejection.problems.single.column, InputField.overallPlace.name);
    });

    test('rejects a fractional fleet size', () {
      // ARRANGE
      final row = legacyRow(
        rowNumber: 7,
        cells: {'Mezőny (hajó)': const LegacyNumber(10.5)},
      );

      // ACT
      final rejection = _rejected(normalizeLegacyRow(row));

      // ASSERT
      expect(rejection.problems.single.column, 'Mezőny (hajó)');
    });
  });
}
