import 'package:web_server/src/polar_lab/apparent_wind_angle.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/lab_sample_tables.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';

/// A polár-összesítő diagnosztikai szakasza: a polárba került minták
/// számolt látszólagos szélszöge ([apparentWindAngleDegrees]) szerint
/// (`docs/PLAN.md` P.3).
///
/// A polár szűrője a lehetetlen mintákat már kidobta
/// (`PolarBuildRejection.apparentWind`); a szakasz azt mutatja, mi maradt
/// a [suspiciousBandsDegrees] sávjaiban: kreuzban ez normális (a műszer
/// TWA-ja élesebbet mér, a számolás nem ismeri a sodródást). Szezononként
/// és forrásonként, valamint TWS-oszloponként mutatja az időt kreuzra
/// (`|TWA|` < 90°) és hátszélre bontva, sávonként, és a sávokba eső minták
/// vízsebességének mediánját. Csak összesített számokat ír.
///
/// Pure függvény.
String apparentWindSection(
  List<LabSample> samples, {
  required PolarBuildAxes axes,
}) {
  final limit = tableNumber(suspiciousBandsDegrees.last);
  final buffer = StringBuffer()
    ..writeln('## 7. Gyanús minták: számolt AWA')
    ..writeln()
    ..writeln(
      'A látszólagos szélszög a TWA-ból, a TWS-ből és a (korrigált) '
      'STW-ből, sodródás és áramlás nélkül. A polár szűrője kreuzban '
      '${tableNumber(PolarBuildRejection.minimumUpwindAwaDegrees)}°, '
      'hátszélben '
      '${tableNumber(PolarBuildRejection.minimumDownwindAwaDegrees)}° alatt '
      'dob (ADR 0058 D6); a kreuz ennél nagyobb, $limit° alatti sávja '
      'normális, mert a műszer TWA-ja élesebbet mér, és a számolás nem '
      'ismeri a sodródást. Csak a polárba került minták, perc. Kreuz: '
      '`|TWA|` < 90°, hátszél: 90° és fölötte; az utolsó oszlop a $limit° '
      'alatti minták STW-mediánja.',
    )
    ..writeln()
    ..writeln('### Szezon és forrás szerint')
    ..writeln()
    ..writeln('| Szezon | Forrás ${_header()}')
    ..writeln('|---|---${_separator()}');
  for (final (:season, :source) in seasonSourcesOf(samples)) {
    final group = [
      for (final sample in samples)
        if (sample.season == season && sample.source == source) sample,
    ];
    buffer.writeln('| $season | ${sourceLabelOf(source)} ${_cells(group)}');
  }
  buffer
    ..writeln()
    ..writeln('### TWS-oszlop szerint (minden szezon)')
    ..writeln()
    ..writeln('| TWS ${_header()}')
    ..writeln('|---${_separator()}');
  for (final (column, knots) in axes.twsColumnsKnots.indexed) {
    final group = [
      for (final sample in samples)
        if (axes.twsColumnOf(sample.twsKnots) == column) sample,
    ];
    buffer.writeln('| ${tableNumber(knots)} ${_cells(group)}');
  }
  return (buffer..writeln()).toString();
}

/// A gyanús AWA-sávok felső határai fokban, növekvő sorrendben.
const List<double> suspiciousBandsDegrees = [10, 15, 20];

double _suspiciousLimit() => suspiciousBandsDegrees.last;

List<String> _bandLabels() => [
  for (final (index, limit) in suspiciousBandsDegrees.indexed)
    index == 0 ? '< ${tableNumber(limit)}°' : _rangeLabel(index),
];

String _rangeLabel(int index) {
  final lower = tableNumber(suspiciousBandsDegrees[index - 1]);
  final upper = tableNumber(suspiciousBandsDegrees[index]);
  return '$lower–$upper°';
}

String _header() {
  final bands = _bandLabels().join(' | ');
  return '| Kreuz | $bands | Hátszél | $bands | STW-medián (kn) |';
}

// A fejléc oszlopai: két oldal (összesen + sávok) és a medián.
String _separator() {
  final columns = 2 * (suspiciousBandsDegrees.length + 1) + 1;
  return '${'|---' * columns}|';
}

// A csoport sorának cellái a nyitó `|` után: kreuz összesen és sávonként,
// hátszél összesen és sávonként, a gyanús minták STW-mediánja.
String _cells(List<LabSample> group) {
  final suspicious = [
    for (final sample in group)
      if (_awaOf(sample) < _suspiciousLimit()) sample,
  ];
  final median = weightedMedianStwOf(suspicious);
  final cells = [
    for (final isUpwind in const [true, false])
      ..._sideCells(group, isUpwind: isUpwind),
    if (median == null) '·' else median.toStringAsFixed(2),
  ];
  return '| ${cells.join(' | ')} |';
}

List<int> _sideCells(List<LabSample> group, {required bool isUpwind}) {
  final side = [
    for (final sample in group)
      if ((sample.absTwaDeg < 90) == isUpwind) sample,
  ];
  return [
    minutesOf(side),
    for (final (index, limit) in suspiciousBandsDegrees.indexed)
      minutesOf(
        side.where((sample) {
          final awa = _awaOf(sample);
          final lower = index == 0 ? 0.0 : suspiciousBandsDegrees[index - 1];
          return awa >= lower && awa < limit;
        }),
      ),
  ];
}

double _awaOf(LabSample sample) => apparentWindAngleDegrees(
  absTwaDeg: sample.absTwaDeg,
  twsKnots: sample.twsKnots,
  stwKnots: sample.stwKnots,
);
