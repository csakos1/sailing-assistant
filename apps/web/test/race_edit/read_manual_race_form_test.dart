import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/manual_race_form_values.dart';
import 'package:foretack_web/race_edit/form/read_manual_race_form.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

void main() {
  final empty = manualEditorValuesOf(null);

  ManualRaceFormValues race({
    String name = 'Siofoki Evadzaro',
    String date = '2025.10.19',
    String distanceKm = '',
    String maxSpeedKnots = '',
    CompassPoint? windPoint,
  }) => (
    name: name,
    date: date,
    distanceKm: distanceKm,
    maxSpeedKnots: maxSpeedKnots,
    avgWindKnots: '',
    maxWindKnots: '',
    windPoint: windPoint,
  );

  ResultFormValues timedResult(String date, String start, String finish) => (
    classPlacing: empty.result.classPlacing,
    overallPlacing: empty.result.overallPlacing,
    monohullPlacing: empty.result.monohullPlacing,
    ysNumber: '',
    startDate: date,
    startTime: start,
    finishTime: finish,
    finishDayOffset: 0,
    prize: '',
    summary: '',
  );

  List<FieldProblem> problemsOf(
    Result<ManualRaceRequest, List<FieldProblem>> r,
  ) => switch (r) {
    Ok(:final value) => throw StateError('Err-t vartunk: $value'),
    Err(:final error) => error,
  };

  group('manualEditorValuesOf', () {
    test('opens a new race with every field empty', () {
      expect(empty.race.name, '');
      expect(empty.race.date, '');
      expect(empty.race.windPoint, isNull);
      expect(empty.result.startDate, '');
    });

    test('prefills a stored race in km and knots', () {
      final values = manualEditorValuesOf(
        RaceSummary(
          id: 'm1',
          name: 'Siofoki Evadzaro',
          // A `!` biztonsagos: letezo nap.
          origin: ManualOrigin(CalendarDate.tryParse('2025-10-19')!),
          stats: RaceStats(
            window: const ManualEntry(),
            track: TrackStats(
              distanceMeters: 10200,
              maxSpeedMps: knotsToMetersPerSecond(7.6),
            ),
            windPoint: CompassPoint.southWest,
          ),
        ),
      );

      expect(values.race.date, '2025.10.19');
      expect(values.race.distanceKm, '10,2');
      expect(values.race.maxSpeedKnots, '7,6');
      expect(values.race.avgWindKnots, '');
      expect(values.race.windPoint, CompassPoint.southWest);
      // A rajt napja a verseny datuma (K11).
      expect(values.result.startDate, '2025.10.19');
    });
  });

  group('readManualRaceForm', () {
    test('builds the request in SI units', () {
      final result = readManualRaceForm(
        race(distanceKm: '10,2', maxSpeedKnots: '7.6'),
        timedResult('2025.10.19', '11:00', '12:24'),
      );

      final request = switch (result) {
        Ok(:final value) => value,
        Err(:final error) => throw StateError('Ok-t vartunk: $error'),
      };
      expect(request.race.name, 'Siofoki Evadzaro');
      expect(request.race.date, CalendarDate.tryParse('2025-10-19'));
      expect(request.race.distanceMeters, closeTo(10200, 1e-6));
      expect(request.race.maxSpeedMps, closeTo(3.9098, 1e-4));
      expect(
        request.result.officialFinish,
        DateTime(2025, 10, 19, 12, 24).toUtc(),
      );
    });

    test('requires a name and a date, and reports both', () {
      final problems = problemsOf(
        readManualRaceForm(race(name: '  ', date: ''), empty.result),
      );

      expect(problems, const [
        RuleBroken(ValueEmpty(InputField.date)),
        RuleBroken(ValueEmpty(InputField.name)),
      ]);
    });

    test('shows a bad date once, not again on the start time', () {
      final problems = problemsOf(
        readManualRaceForm(
          race(date: '2025.13.40'),
          timedResult('2025.13.40', '11:00', ''),
        ),
      );

      expect(problems, const [
        TextNotReadable(InputField.date, TextFormat.date),
      ]);
    });

    test('reports an unreadable quantity under its field', () {
      final problems = problemsOf(
        readManualRaceForm(race(distanceKm: '10 km'), empty.result),
      );

      expect(problems, const [
        TextNotReadable(InputField.distanceMeters, TextFormat.decimalNumber),
      ]);
    });
  });

  group('formAverageSpeedMps', () {
    test('divides the distance by the official elapsed time', () {
      expect(
        formAverageSpeedMps('3,6', const Duration(hours: 1)),
        closeTo(1, 1e-9),
      );
    });

    test('is missing without a distance or a positive elapsed time', () {
      expect(formAverageSpeedMps('', const Duration(hours: 1)), isNull);
      expect(formAverageSpeedMps('3,6', null), isNull);
      expect(formAverageSpeedMps('3,6', Duration.zero), isNull);
    });
  });
}
