import 'package:domain/domain.dart';
import 'package:web_server/src/polar_lab/apparent_wind_section.dart';
import 'package:web_server/src/polar_lab/polar_build.dart';
import 'package:web_server/src/polar_lab/polar_build_accounting.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';

/// A polár-építés markdown-összesítője (ADR 0058 D7 5., D9).
///
/// Csak összesített számokat ír (szezononkénti idő, cellánkénti mért idő,
/// nyers p90 és kész érték, VMG-optimum): nyers minta, időbélyeg, pozíció
/// és versenynév nincs benne, így megosztható. A [newPolar] a kész `.pol`
/// visszaolvasva, az [oldPolar] a mostani polár az összevetéshez. A
/// [tolerance] a kész érték megengedett eltérése a nyers p90-től (arány), a
/// [steadyWindRangeDegrees] az állandósult szél szűrőjének küszöbe (csak a
/// leíráshoz; a szűrés a gyűjtéskor történt).
///
/// Pure függvény: ugyanarra a bemenetre ugyanazt a szöveget adja.
String polarBuildSummary({
  required PolarBuild build,
  required Polar oldPolar,
  required Polar newPolar,
  required String oldPolarLabel,
  double tolerance = 0.03,
  double steadyWindRangeDegrees = 12,
}) {
  final parameters = build.parameters;
  final summary = StringBuffer()
    ..writeln('# Polár-építés (ADR 0058)')
    ..writeln()
    ..writeln(
      'Régi polár az összevetéshez: `$oldPolarLabel`. Mért cella: '
      '≥ ${parameters.minimumMeasuredSeconds} mp. TWA-simítás: '
      '±${_number(parameters.twaBandwidthDegrees)}°. Ellenőrzés: '
      '±${_number(tolerance * 100)}%.',
    )
    ..writeln()
    ..write(_accountingSection(build.accounting, steadyWindRangeDegrees))
    ..write(_axisSection(build))
    ..write(_valuesSection(build))
    ..write(_minutesSection(build))
    ..write(_deviationSection(build, tolerance))
    ..write(_vmgSection(build, oldPolar: oldPolar, newPolar: newPolar))
    ..write(
      apparentWindSection(build.acceptedSamples, axes: build.smoothed.axes),
    );
  return summary.toString();
}

const String _empty = '·';

String _accountingSection(
  List<PolarBuildSeasonAccounting> accounting,
  double steadyWindRangeDegrees,
) {
  final buffer = StringBuffer()
    ..writeln('## 1. Adat szezononként (perc)')
    ..writeln()
    ..writeln(
      'Érvényes: a webes szűrők után. Utána a polár szűrői (ADR 0058 D6): '
      'nem állandósult szél (±10 mp-en a `|TWA|` terjedelme ≥ '
      '${_number(steadyWindRangeDegrees)}°), '
      'vízsebesség (0,3 kn vagy kevesebb, 12 kn vagy több), szélcsend '
      '(`|TWA|` ≥ 177,5° és TWS < 2 kn), 1 kn alatti szél, no-go.',
    )
    ..writeln()
    ..writeln(
      '| Szezon | Verseny | Érvényes | Nem állandó szél | Vízsebesség '
      '| Szélcsend | 1 kn alatt | No-go | Polárba |',
    )
    ..writeln('|---|---|---|---|---|---|---|---|---|');
  for (final season in accounting) {
    final rejected = season.rejectedSeconds;
    final cells = [
      season.season,
      season.raceCount,
      _minutes(season.validSeconds),
      _minutes(season.unsteadySeconds),
      for (final reason in PolarBuildRejection.values)
        _minutes(rejected[reason] ?? 0),
      _minutes(season.usedSeconds),
    ];
    buffer.writeln('| ${cells.join(' | ')} |');
  }
  return (buffer..writeln()).toString();
}

String _axisSection(PolarBuild build) {
  final axes = build.smoothed.axes;
  final verdict = axes.hasStrongWindColumn ? 'bekerült' : 'nem került be';
  final buffer = StringBuffer()
    ..writeln('## 2. Tengely')
    ..writeln()
    ..writeln(
      'TWS: ${axes.twsColumnsKnots.map(_number).join(', ')} kn. A '
      '${_number(PolarBuildAxes.strongWindColumnKnots)} csomós oszlop '
      'tartományában ${_minutes(build.strongWindSeconds)} perc mért idő '
      'van (küszöb: '
      '${_minutes(PolarBuildAxes.strongWindColumnMinimumSeconds)} perc), '
      'ezért $verdict.',
    )
    ..writeln();
  return buffer.toString();
}

String _valuesSection(PolarBuild build) {
  final smoothed = build.smoothed;
  final table = _gridTable(smoothed.axes, (row, column) {
    final value = smoothed.valueAt(row, column);
    if (value == null) return _empty;
    final mark = switch (smoothed.originAt(row, column)) {
      PolarCellOrigin.measured || PolarCellOrigin.empty => '',
      PolarCellOrigin.smoothedAlongTwa => '~',
      PolarCellOrigin.filledAlongTws => '*',
    };
    return '${value.toStringAsFixed(2)}$mark';
  });
  final buffer = StringBuffer()
    ..writeln('## 3. Az új polár (kn)')
    ..writeln()
    ..writeln(
      'Szám: mért cella. `~`: a TWA menti simítás töltötte. `*`: a TWS '
      'menti töltés adta (interpoláció, tartás vagy horgony). $_empty: '
      'üres.',
    )
    ..writeln()
    ..write(table);
  return buffer.toString();
}

String _minutesSection(PolarBuild build) {
  final table = _gridTable(build.raw.axes, (row, column) {
    final cell = build.raw.cellAt(row, column);
    return cell == null ? _empty : _minutes(cell.seconds).toString();
  });
  final buffer = StringBuffer()
    ..writeln('## 4. Mért idő (perc)')
    ..writeln()
    ..write(table);
  return buffer.toString();
}

String _deviationSection(PolarBuild build, double tolerance) {
  final outliers = <String>[];
  final table = _gridTable(build.raw.axes, (row, column) {
    final deviation = _deviationAt(build, row, column);
    if (deviation == null) return _empty;
    final text = _signed(deviation * 100);
    if (deviation.abs() <= tolerance) return text;
    outliers.add(_outlierLine(build, row, column, deviation));
    return '**$text**';
  });
  final buffer = StringBuffer()
    ..writeln('## 5. Eltérés a nyers p90-től (%)')
    ..writeln()
    ..writeln(
      'Csak a mért cellák. A ±${_number(tolerance * 100)}% fölötti '
      'eltérés félkövér; ${outliers.length} ilyen cella van.',
    )
    ..writeln()
    ..write(table)
    ..writeAll(outliers.map((line) => '- $line\n'));
  if (outliers.isNotEmpty) buffer.writeln();
  return buffer.toString();
}

// A kész érték eltérése a nyers p90-től (arány), vagy `null`, ha a cella
// nem mért.
double? _deviationAt(PolarBuild build, int row, int column) {
  if (build.smoothed.originAt(row, column) != PolarCellOrigin.measured) {
    return null;
  }
  final raw = build.raw.cellAt(row, column);
  final value = build.smoothed.valueAt(row, column);
  if (raw == null || value == null) return null;
  return (value - raw.p90Knots) / raw.p90Knots;
}

String _outlierLine(PolarBuild build, int row, int column, double deviation) {
  // A `!` biztonságos: az eltérés csak mért, értékes cellára számol.
  final raw = build.raw.cellAt(row, column)!;
  final value = build.smoothed.valueAt(row, column)!;
  final twaDeg = PolarBuildAxes.twaDegreesOfRow(row);
  final twsKnots = _number(build.raw.axes.twsColumnsKnots[column]);
  return '$twaDeg° @ $twsKnots kn: nyers ${raw.p90Knots.toStringAsFixed(2)}, '
      'kész ${value.toStringAsFixed(2)} (${_signed(deviation * 100)}%, '
      '${_minutes(raw.seconds)} perc)';
}

String _vmgSection(
  PolarBuild build, {
  required Polar oldPolar,
  required Polar newPolar,
}) {
  final buffer = StringBuffer()
    ..writeln('## 6. VMG-optimum (régi és új polár)')
    ..writeln()
    ..writeln(
      'A legjobb VMG-t adó `|TWA|` és a VMG (kn) az új tengely oszlopain. A '
      'régi polár a saját tengelye alatt és fölött a szélső oszlopát adja.',
    )
    ..writeln()
    ..writeln(
      '| TWS | Kreuz: régi | Kreuz: új | Hátszél: régi | Hátszél: új |',
    )
    ..writeln('|---|---|---|---|---|');
  for (final twsKnots in build.smoothed.axes.twsColumnsKnots) {
    final cells = [
      _number(twsKnots),
      for (final twaDegrees in const [45.0, 150.0])
        for (final polar in [oldPolar, newPolar])
          _optimumText(polar, twsKnots, twaDegrees),
    ];
    buffer.writeln('| ${cells.join(' | ')} |');
  }
  return (buffer..writeln()).toString();
}

const _lookupTargetVmg = LookupTargetVmg();

// A [twaDegrees] a halz-irányt választja (kreuz vagy hátszél).
String _optimumText(Polar polar, double twsKnots, double twaDegrees) {
  final optimum = _lookupTargetVmg(
    polar: polar,
    twaDegrees: twaDegrees,
    twsKnots: twsKnots,
  );
  if (optimum == null) return _empty;
  return '${optimum.optimumTwaDegrees.round()}° / '
      '${optimum.vmgKnots.abs().toStringAsFixed(2)}';
}

String _gridTable(
  PolarBuildAxes axes,
  String Function(int row, int column) cellOf,
) {
  final columns = axes.twsColumnsKnots.map(_number);
  final buffer = StringBuffer()
    ..writeln('| TWA \\ TWS | ${columns.join(' | ')} |')
    ..writeln('|---|${List.filled(columns.length, '---').join('|')}|');
  const first = PolarBuildAxes.firstSailingTwaRow;
  for (var row = first; row < PolarBuildAxes.twaRowCount; row++) {
    final cells = [
      for (var column = 0; column < columns.length; column++)
        cellOf(row, column),
    ];
    buffer.writeln(
      '| ${PolarBuildAxes.twaDegreesOfRow(row)} | ${cells.join(' | ')} |',
    );
  }
  return (buffer..writeln()).toString();
}

int _minutes(int seconds) => (seconds / 60).round();

String _signed(double value) {
  final text = value.toStringAsFixed(1);
  return value >= 0 ? '+$text' : text;
}

// Az egész szám tizedes nélkül (`10`), a tört egy tizedessel (`2.5`).
String _number(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
