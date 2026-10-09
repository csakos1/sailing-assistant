import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/manual_race_form_values.dart';
import 'package:foretack_web/race_edit/form/read_result_form.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A kézi szerkesztő olvasása és validálása: az alapadatok és az eredmény
/// együtt (ADR 0048 Addendum 4 K11).
///
/// Mint a `readResultForm`: előbb a szövegek, aztán a szerződés
/// `ValidateManualRaceInput`-ja, és **minden** hiba egyszerre jön vissza.
/// A dátum kötelező; hiányát `ValueEmpty` jelzi. A hivatalos rajt napja a
/// verseny dátuma, ezért egy rossz dátum mellett a rajt napjának ugyanaz a
/// hibája nem ismétlődik az idő-mezőn.
Result<ManualRaceRequest, List<FieldProblem>> readManualRaceForm(
  ManualRaceFormValues race,
  ResultFormValues result,
) {
  final problems = <FieldProblem>[];
  T? read<T>(Result<T?, TextFormat> parsed, InputField field) {
    switch (parsed) {
      case Ok(:final value):
        return value;
      case Err(:final error):
        problems.add(TextNotReadable(field, error));
        return null;
    }
  }

  final date = read(parseFormDate(race.date), InputField.date);
  final hasDateProblem = problems.isNotEmpty;
  if (date == null && !hasDateProblem) {
    problems.add(const RuleBroken(ValueEmpty(InputField.date)));
  }
  final input = ManualRaceInput(
    name: race.name,
    // Dátum nélkül is lefut a validáció, hogy a név és a statok hibái is
    // egyszerre jöjjenek; a helyettes nap sosem megy a szerverre.
    date: date ?? _placeholderDate,
    distanceMeters: _scaled(
      read(parseDecimal(race.distanceKm), InputField.distanceMeters),
      1000,
    ),
    maxSpeedMps: _knots(
      read(parseDecimal(race.maxSpeedKnots), InputField.maxSpeedMps),
    ),
    avgWindMps: _knots(
      read(parseDecimal(race.avgWindKnots), InputField.avgWindMps),
    ),
    maxWindMps: _knots(
      read(parseDecimal(race.maxWindKnots), InputField.maxWindMps),
    ),
    windPoint: race.windPoint,
  );

  final validatedRace = _validateRace(input);
  final readResult = readResultForm(result);
  final allProblems = [
    ...problems,
    ..._violationsOf(validatedRace),
    ..._problemsOf(readResult).where(
      // A rajt napja a verseny dátuma: a hibája a dátum-mezőn már látszik.
      (problem) => !(date == null && _isStartDateProblem(problem)),
    ),
  ];
  return switch ((validatedRace, readResult)) {
    (Ok(value: final validRace), Ok(value: final validResult))
        when allProblems.isEmpty =>
      Ok(ManualRaceRequest(race: validRace, result: validResult)),
    _ => Err(allProblems),
  };
}

/// A számolt átlagsebesség m/s-ben: a táv (km) és a hivatalos menetidő
/// hányadosa, ha mindkettő megvan (K11, „SZÁMOLT · TÁV ÷ MENETIDŐ").
double? formAverageSpeedMps(String distanceKm, Duration? elapsed) {
  final distance = switch (parseDecimal(distanceKm)) {
    Ok(:final value) => value,
    Err() => null,
  };
  if (distance == null || elapsed == null || elapsed <= Duration.zero) {
    return null;
  }
  return distance * 1000 / (elapsed.inMilliseconds / 1000);
}

const ValidateManualRaceInput _validateRace = ValidateManualRaceInput();

// Egy létező nap, amely csak a validáció lefuttatásához kell; a `!`
// ezért biztonságos.
final CalendarDate _placeholderDate = CalendarDate.tryFromParts(
  year: 2000,
  month: 1,
  day: 1,
)!;

bool _isStartDateProblem(FieldProblem problem) =>
    problem is TextNotReadable &&
    problem.field == InputField.officialStart &&
    problem.format == TextFormat.date;

double? _scaled(double? value, double factor) =>
    value == null ? null : value * factor;

double? _knots(double? knots) =>
    knots == null ? null : knotsToMetersPerSecond(knots);

List<FieldProblem> _violationsOf(
  Result<ManualRaceInput, List<InputViolation>> result,
) => switch (result) {
  Ok() => const [],
  Err(:final error) => [for (final violation in error) RuleBroken(violation)],
};

List<FieldProblem> _problemsOf(
  Result<RaceResultInput, List<FieldProblem>> result,
) => switch (result) {
  Ok() => const [],
  Err(:final error) => error,
};
