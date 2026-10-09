import 'package:foretack_web/race_edit/form/clock_time.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';
import 'package:foretack_web/race_edit/form/result_form_values.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// Az eredmény-űrlap olvasása és validálása (ADR 0048 Addendum 4 K11).
///
/// Két lépcső, mindkettő pure:
///  1. a szövegek olvasása; ami nem olvasható, az [TextNotReadable];
///  2. a szerződés `ValidateRaceResultInput`-ja az olvasható részen; a
///     szabálysértések [RuleBroken]-ként jönnek.
///
/// **Minden** hiba együtt jön vissza, hogy az űrlap egyszerre jelezze
/// őket. Siker esetén a normalizált bemenet utazik a szerverre.
Result<RaceResultInput, List<FieldProblem>> readResultForm(
  ResultFormValues values,
) {
  final reader = _ProblemCollector();
  final startTime = reader.read(
    parseClockTime(values.startTime),
    InputField.officialStart,
  );
  final finishTime = reader.read(
    parseClockTime(values.finishTime),
    InputField.officialFinish,
  );
  final startDate = startTime == null && finishTime == null
      ? null
      : _readStartDate(values.startDate, reader);

  final input = RaceResultInput(
    classPlace: _readPlacing(
      values.classPlacing,
      InputField.classPlace,
      reader,
    ),
    classFleetSize: reader.read(
      parseWholeNumber(values.classPlacing.fleetSize),
      InputField.classFleetSize,
    ),
    overallPlace: _readPlacing(
      values.overallPlacing,
      InputField.overallPlace,
      reader,
    ),
    overallFleetSize: reader.read(
      parseWholeNumber(values.overallPlacing.fleetSize),
      InputField.overallFleetSize,
    ),
    monohullPlace: _readPlacing(
      values.monohullPlacing,
      InputField.monohullPlace,
      reader,
    ),
    monohullFleetSize: reader.read(
      parseWholeNumber(values.monohullPlacing.fleetSize),
      InputField.monohullFleetSize,
    ),
    ysNumberHundredths: reader.read(
      parseYsNumber(values.ysNumber),
      InputField.ysNumberHundredths,
    ),
    officialStart: _instant(startDate, startTime),
    officialFinish: _instant(
      startDate,
      finishTime,
      dayOffset: values.finishDayOffset,
    ),
    prize: values.prize,
    summary: values.summary,
  );

  return switch (_validate(input)) {
    Ok(:final value) when reader.problems.isEmpty => Ok(value),
    Ok() => Err(reader.problems),
    Err(:final error) => Err([
      ...reader.problems,
      for (final violation in error) RuleBroken(violation),
    ]),
  };
}

/// A hivatalos menetidő az űrlap mostani szövegeiből, ha a rajt, a
/// befutás és a nap is olvasható, és a befutás a rajt után van; különben
/// `null`. A „SZÁMOLT" sor élő értéke (K11).
Duration? formOfficialElapsed(ResultFormValues values) {
  final date = _valueOrNull(parseFormDate(values.startDate));
  final start = _instant(date, _valueOrNull(parseClockTime(values.startTime)));
  final finish = _instant(
    date,
    _valueOrNull(parseClockTime(values.finishTime)),
    dayOffset: values.finishDayOffset,
  );
  if (start == null || finish == null || !finish.isAfter(start)) return null;
  return finish.difference(start);
}

const ValidateRaceResultInput _validate = ValidateRaceResultInput();

Placing? _readPlacing(
  PlacingFormValues values,
  InputField placeField,
  _ProblemCollector reader,
) => switch (values.kind) {
  PlacingKind.dnf => const Dnf(),
  PlacingKind.dsq => const Dsq(),
  PlacingKind.number => switch (reader.read(
    parseWholeNumber(values.place),
    placeField,
  )) {
    null => null,
    final int place => FinishPlace(place),
  },
};

// A rajt napja csak akkor kell, ha van idő; hiánya ilyenkor hiba, mert
// nap nélkül az idő nem pillanat.
CalendarDate? _readStartDate(String text, _ProblemCollector reader) {
  final date = reader.read(parseFormDate(text), InputField.officialStart);
  if (date == null && text.trim().isEmpty) {
    reader.problems.add(
      const TextNotReadable(InputField.officialStart, TextFormat.date),
    );
  }
  return date;
}

DateTime? _instant(CalendarDate? date, ClockTime? time, {int dayOffset = 0}) =>
    date == null || time == null
    ? null
    : localInstant(date, time, dayOffset: dayOffset);

T? _valueOrNull<T>(Result<T?, TextFormat> result) => switch (result) {
  Ok(:final value) => value,
  Err() => null,
};

/// Gyűjti az olvasási hibákat; a hibás mező értéke `null` lesz.
class _ProblemCollector {
  final List<FieldProblem> problems = [];

  T? read<T>(Result<T?, TextFormat> result, InputField field) {
    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final error):
        problems.add(TextNotReadable(field, error));
        return null;
    }
  }
}
