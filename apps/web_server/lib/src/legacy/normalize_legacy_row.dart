import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/legacy/legacy_columns.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';
import 'package:web_server/src/legacy/legacy_row_reader.dart';
import 'package:web_server/src/legacy/legacy_row_rejection.dart';
import 'package:web_server/src/legacy/legacy_sheet_row.dart';
import 'package:web_server/src/legacy/legacy_two_day_results.dart';

/// Egy Excel-sor normalizálása és validálása (ADR 0048 D7, Addendum 6
/// M2, M5).
///
/// Pure. A hibás sort `LegacyRowRejection`-nel adja vissza, minden
/// hibájával; az ilyen sor egyik formában sem íródik.
Result<LegacyRace, LegacyRowRejection> normalizeLegacyRow(
  LegacySheetRow row,
) {
  final reader = LegacyRowReader(row);
  final name = reader.requiredText(legacyNameColumn);
  final date = reader.requiredDate(legacyDateColumn);
  final draft = _ResultDraft.read(reader);
  final stats = _ManualStats.read(reader);
  if (name == null || date == null || reader.problems.isNotEmpty) {
    return Err(
      LegacyRowRejection(
        rowNumber: row.rowNumber,
        name: name,
        problems: reader.problems,
      ),
    );
  }
  final violations = <LegacyRowProblem>[];
  final result = _validResult(draft.wholeRace(), violations);
  final manualRace = _validManualRace(stats.toInput(name, date), violations);
  final twoDayResults = draft.hasSecondDay
      ? LegacyTwoDayResults(
          first: _validResult(draft.firstDay(), violations),
          second: _validResult(draft.secondDay(), violations),
        )
      : null;
  if (violations.isNotEmpty) {
    return Err(
      LegacyRowRejection(
        rowNumber: row.rowNumber,
        name: name,
        problems: violations,
      ),
    );
  }
  return Ok(
    LegacyRace(
      rowNumber: row.rowNumber,
      name: name,
      date: date,
      result: result,
      manualRace: manualRace,
      twoDayResults: twoDayResults,
      notes: [...reader.notes, ...draft.notes],
    ),
  );
}

const String _dnfMarker = 'DNF';

// Az Excel „nincs díj" jele (ADR 0048 D7).
const String _noPrizeMarker = '-';

const double _metersPerNauticalMile = 1852;
const double _metersPerSecondPerKnot = _metersPerNauticalMile / 3600;

RaceResultInput _validResult(
  RaceResultInput input,
  List<LegacyRowProblem> violations,
) {
  switch (const ValidateRaceResultInput()(input)) {
    case Ok(:final value):
      return value;
    case Err(:final error):
      violations.addAll(error.map(_problemOf));
      return input;
  }
}

ManualRaceInput _validManualRace(
  ManualRaceInput input,
  List<LegacyRowProblem> violations,
) {
  switch (const ValidateManualRaceInput()(input)) {
    case Ok(:final value):
      return value;
    case Err(:final error):
      violations.addAll(error.map(_problemOf));
      return input;
  }
}

LegacyRowProblem _problemOf(InputViolation violation) => LegacyRowProblem(
  column: violation.field.name,
  kind: LegacyProblemKind.invalid,
  detail: _violationName(violation),
);

// Kimerítő switch a `runtimeType` helyett: a név így obfuszkált buildben
// is olvasható marad.
String _violationName(InputViolation violation) => switch (violation) {
  ValueNotPositive() => 'nem pozitív',
  PlaceExceedsFleetSize() => 'nagyobb a mezőnynél',
  FinishNotAfterStart() => 'a befutás nem a rajt után van',
  ValueNegative() => 'negatív',
  ValueEmpty() => 'üres',
};

/// Az eredmény-oszlopok olvasott értékei, mielőtt a forma (egész verseny
/// vagy két nap) eldől.
final class _ResultDraft {
  _ResultDraft._({
    required this.classPlace,
    required this.overallPlace,
    required this.monohullPlace,
    required this.overallSecondDay,
    required this.monohullSecondDay,
    required this.fleetSize,
    required this.ysNumberHundredths,
    required this.officialStart,
    required this.officialFinish,
    required this.prize,
    required this.notes,
  });

  factory _ResultDraft.read(LegacyRowReader reader) {
    final isDnf = reader.hasMarker(legacyFinishColumn, _dnfMarker);
    final ys = reader.number(legacyYsColumn);
    final prize = reader.optionalText(legacyPrizeColumn);
    // A Befutás DNF-je mindhárom helyezést DNF-re állítja (ADR 0048 D7).
    Placing? placingOf(String column) {
      final placing = reader.placing(column);
      return isDnf ? const Dnf() : placing;
    }

    // A 2. nap oszlopa csak akkor lesz DNF, ha ki van töltve: az üres
    // oszlop nem teheti kétnapossá az egynapos sort.
    Placing? secondDayOf(String column) {
      final placing = reader.placing(column);
      return isDnf && placing != null ? const Dnf() : placing;
    }

    return _ResultDraft._(
      classPlace: placingOf(legacyClassPlaceColumn),
      overallPlace: placingOf(legacyOverallPlaceColumn),
      monohullPlace: placingOf(legacyMonohullPlaceColumn),
      overallSecondDay: secondDayOf(legacyOverallSecondDayColumn),
      monohullSecondDay: secondDayOf(legacyMonohullSecondDayColumn),
      fleetSize: reader.wholeNumber(legacyFleetColumn),
      ysNumberHundredths: ys == null ? null : (ys * 100).round(),
      officialStart: reader.instant(legacyStartColumn),
      officialFinish: reader.instant(
        legacyFinishColumn,
        skippedMarker: _dnfMarker,
      ),
      prize: prize == _noPrizeMarker ? null : prize,
      notes: [if (isDnf) '$legacyFinishColumn: DNF → mindhárom helyezés DNF'],
    );
  }

  final Placing? classPlace;
  final Placing? overallPlace;
  final Placing? monohullPlace;
  final Placing? overallSecondDay;
  final Placing? monohullSecondDay;
  final int? fleetSize;
  final int? ysNumberHundredths;
  final DateTime? officialStart;
  final DateTime? officialFinish;
  final String? prize;
  final List<String> notes;

  bool get hasSecondDay =>
      overallSecondDay != null || monohullSecondDay != null;

  /// Az egész verseny eredménye, ahogy a sorban áll.
  ///
  /// Kétnapos sornál a hivatalos idők kimaradnak (M5): a két napot
  /// átfogó ablak egy napi rögzítésre vagy egy kézi verseny menetidejére
  /// hamis statisztikát adna.
  RaceResultInput wholeRace() => RaceResultInput(
    classPlace: classPlace,
    overallPlace: overallPlace,
    overallFleetSize: fleetSize,
    monohullPlace: monohullPlace,
    ysNumberHundredths: ysNumberHundredths,
    officialStart: hasSecondDay ? null : officialStart,
    officialFinish: hasSecondDay ? null : officialFinish,
    prize: prize,
  );

  // M5: az 1. nap az 1. napi helyezéseket kapja; hivatalos idő nincs,
  // mert a sor a két napot egybefogja.
  RaceResultInput firstDay() => RaceResultInput(
    overallPlace: overallPlace,
    overallFleetSize: fleetSize,
    monohullPlace: monohullPlace,
    ysNumberHundredths: ysNumberHundredths,
  );

  // M5: a 2. nap a „2. nap" helyezéseit, az összesített osztály-helyezést
  // és a díjat kapja.
  RaceResultInput secondDay() => RaceResultInput(
    classPlace: classPlace,
    overallPlace: overallSecondDay,
    overallFleetSize: fleetSize,
    monohullPlace: monohullSecondDay,
    ysNumberHundredths: ysNumberHundredths,
    prize: prize,
  );
}

/// A kézi verseny beírt statjai SI-mértékegységben (ADR 0048 D7).
final class _ManualStats {
  _ManualStats._({
    required this.distanceMeters,
    required this.maxSpeedMps,
    required this.avgWindMps,
    required this.maxWindMps,
    required this.windPoint,
  });

  factory _ManualStats.read(LegacyRowReader reader) => _ManualStats._(
    distanceMeters: _scaled(
      reader.number(legacyDistanceColumn),
      _metersPerNauticalMile,
    ),
    maxSpeedMps: _scaled(
      reader.number(legacyMaxSpeedColumn),
      _metersPerSecondPerKnot,
    ),
    avgWindMps: _scaled(
      reader.number(legacyAvgWindColumn),
      _metersPerSecondPerKnot,
    ),
    maxWindMps: _scaled(
      reader.number(legacyMaxWindColumn),
      _metersPerSecondPerKnot,
    ),
    windPoint: reader.compassPoint(legacyWindPointColumn),
  );

  final double? distanceMeters;
  final double? maxSpeedMps;
  final double? avgWindMps;
  final double? maxWindMps;
  final CompassPoint? windPoint;

  ManualRaceInput toInput(String name, CalendarDate date) => ManualRaceInput(
    name: name,
    date: date,
    distanceMeters: distanceMeters,
    maxSpeedMps: maxSpeedMps,
    avgWindMps: avgWindMps,
    maxWindMps: maxWindMps,
    windPoint: windPoint,
  );

  static double? _scaled(double? value, double factor) =>
      value == null ? null : value * factor;
}
