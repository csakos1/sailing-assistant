import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/read_result_form.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

// Az eredmeny-urlap olvasasa: a szovegekbol bemenet, vagy minden hiba
// egyszerre. Az idok helyi DateTime-mal keszulnek (lasd local_instant).

void main() {
  // A `!` biztonsagos: letezo nap.
  final july26 = CalendarDate.tryFromParts(year: 2026, month: 7, day: 26)!;
  final emptyValues = resultFormValuesOf(null, startDate: july26);

  PlacingFormValues pair(String place, String fleetSize) =>
      (kind: PlacingKind.number, place: place, fleetSize: fleetSize);

  RaceResultInput inputOf(ResultFormValues values) =>
      switch (readResultForm(values)) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };

  List<FieldProblem> problemsOf(ResultFormValues values) =>
      switch (readResultForm(values)) {
        Ok(:final value) => throw StateError('Err-t vartunk: $value'),
        Err(:final error) => error,
      };

  group('resultFormValuesOf', () {
    test('prefills an empty form with the start day only', () {
      expect(emptyValues.startDate, '2026.07.26');
      expect(emptyValues.overallPlacing, pair('', ''));
      expect(emptyValues.finishDayOffset, 0);
    });

    test('prefills placings, the YS number and local times', () {
      final values = resultFormValuesOf(
        RaceResultInput(
          overallPlace: const FinishPlace(3),
          overallFleetSize: 24,
          classPlace: const Dnf(),
          classFleetSize: 9,
          ysNumberHundredths: 7590,
          officialStart: DateTime(2026, 7, 26, 11).toUtc(),
          officialFinish: DateTime(2026, 7, 27, 9, 40, 15).toUtc(),
          prize: 'kupa',
        ),
        startDate: july26,
      );

      expect(values.overallPlacing, pair('3', '24'));
      expect(values.classPlacing, (
        kind: PlacingKind.dnf,
        place: '',
        fleetSize: '9',
      ));
      expect(values.ysNumber, '75,90');
      expect(values.startTime, '11:00');
      expect(values.finishTime, '09:40:15');
      expect(values.finishDayOffset, 1);
      expect(values.prize, 'kupa');
      expect(values.summary, '');
    });
  });

  group('readResultForm', () {
    test('reads an empty form as an empty result', () {
      expect(inputOf(emptyValues).isEmpty, isTrue);
    });

    test('reads placings, the YS number and the official window', () {
      final values = (
        classPlacing: (kind: PlacingKind.dsq, place: '4', fleetSize: '9'),
        overallPlacing: pair('3', '24'),
        monohullPlacing: pair('', ''),
        ysNumber: '75.90',
        startDate: '2026.07.26',
        startTime: '1100',
        finishTime: '9:40',
        finishDayOffset: 1,
        prize: '  kupa  ',
        summary: '',
      );

      final input = inputOf(values);

      // A DSQ melletti beirt hely eldobodik (K11).
      expect(input.classPlace, const Dsq());
      expect(input.classFleetSize, 9);
      expect(input.overallPlace, const FinishPlace(3));
      expect(input.overallFleetSize, 24);
      expect(input.monohullPlace, isNull);
      expect(input.ysNumberHundredths, 7590);
      expect(input.officialStart, DateTime(2026, 7, 26, 11).toUtc());
      expect(input.officialFinish, DateTime(2026, 7, 27, 9, 40).toUtc());
      expect(input.prize, 'kupa');
      expect(input.summary, isNull);
    });

    test('reports every unreadable field and rule at once', () {
      final values = (
        classPlacing: pair('x', ''),
        overallPlacing: pair('25', '24'),
        monohullPlacing: pair('', ''),
        ysNumber: '75,9',
        startDate: '2026.07.26',
        startTime: '11:00',
        finishTime: '10:00',
        finishDayOffset: 0,
        prize: '',
        summary: '',
      );

      expect(problemsOf(values), [
        const TextNotReadable(InputField.classPlace, TextFormat.wholeNumber),
        const TextNotReadable(
          InputField.ysNumberHundredths,
          TextFormat.ysNumber,
        ),
        const RuleBroken(PlaceExceedsFleetSize(InputField.overallPlace)),
        const RuleBroken(FinishNotAfterStart()),
      ]);
    });

    test('needs a start day when a time is given', () {
      final values = (
        classPlacing: pair('', ''),
        overallPlacing: pair('', ''),
        monohullPlacing: pair('', ''),
        ysNumber: '',
        startDate: '',
        startTime: '',
        finishTime: '16:40',
        finishDayOffset: 0,
        prize: '',
        summary: '',
      );

      expect(problemsOf(values), [
        const TextNotReadable(InputField.officialStart, TextFormat.date),
      ]);
    });

    test('ignores the start day while no time is given', () {
      final values = (
        classPlacing: pair('', ''),
        overallPlacing: pair('', ''),
        monohullPlacing: pair('', ''),
        ysNumber: '',
        startDate: 'rossz',
        startTime: '',
        finishTime: '',
        finishDayOffset: 0,
        prize: '',
        summary: '',
      );

      expect(inputOf(values).isEmpty, isTrue);
    });
  });

  group('formOfficialElapsed', () {
    ResultFormValues timed(String start, String finish, int dayOffset) => (
      classPlacing: pair('', ''),
      overallPlacing: pair('', ''),
      monohullPlacing: pair('', ''),
      ysNumber: '',
      startDate: '2026.07.26',
      startTime: start,
      finishTime: finish,
      finishDayOffset: dayOffset,
      prize: '',
      summary: '',
    );

    test('counts from the start to the finish across days', () {
      expect(
        formOfficialElapsed(timed('11:00', '9:41', 1)),
        const Duration(hours: 22, minutes: 41),
      );
    });

    test('is missing while a time is missing or out of order', () {
      expect(formOfficialElapsed(timed('11:00', '', 0)), isNull);
      expect(formOfficialElapsed(timed('11:00', '10:00', 0)), isNull);
    });
  });
}
