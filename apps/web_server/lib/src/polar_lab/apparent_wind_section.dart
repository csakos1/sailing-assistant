import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/apparent_wind_angle.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

/// A polár-összesítő diagnosztikai szakasza: a polárba került minták
/// számolt látszólagos szélszöge ([apparentWindAngleDegrees]) szerint
/// (`docs/PLAN.md` P.3).
///
/// Ennyire szemből jövő látszólagos szélben ([suspiciousBandsDegrees]
/// legfelső határa alatt) vitorlával nem, vagy alig lehet haladni: az ilyen
/// minta motoros szakasz vagy szélmérési hiba. A szakasz szezononként és
/// forrásonként, valamint TWS-oszloponként mutatja az időt kreuzra
/// (`|TWA|` < 90°) és hátszélre bontva, sávonként, és a gyanús minták
/// vízsebességének mediánját. Csak összesített számokat ír.
///
/// Pure függvény.
String apparentWindSection(
  List<LabSample> samples, {
  required PolarBuildAxes axes,
}) {
  final limit = _number(suspiciousBandsDegrees.last);
  final buffer = StringBuffer()
    ..writeln('## 7. Gyanús minták: számolt AWA')
    ..writeln()
    ..writeln(
      'A látszólagos szélszög a TWA-ból, a TWS-ből és a (korrigált) '
      'STW-ből, sodródás és áramlás nélkül. $limit° alatt vitorlával nem, '
      'vagy alig lehet haladni: ezek motoros szakaszok vagy szélmérési '
      'hibák. Csak a polárba került minták, perc. Kreuz: `|TWA|` < 90°, '
      'hátszél: 90° és fölötte; az utolsó oszlop a $limit° alatti minták '
      'STW-mediánja.',
    )
    ..writeln()
    ..writeln('### Szezon és forrás szerint')
    ..writeln()
    ..writeln('| Szezon | Forrás ${_header()}')
    ..writeln('|---|---${_separator()}');
  for (final (:season, :source) in _seasonSourcesOf(samples)) {
    final group = [
      for (final sample in samples)
        if (sample.season == season && sample.source == source) sample,
    ];
    buffer.writeln('| $season | ${_sourceLabel(source)} ${_cells(group)}');
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
    buffer.writeln('| ${_number(knots)} ${_cells(group)}');
  }
  return (buffer..writeln()).toString();
}

/// A gyanús AWA-sávok felső határai fokban, növekvő sorrendben.
const List<double> suspiciousBandsDegrees = [10, 15, 20];

double _suspiciousLimit() => suspiciousBandsDegrees.last;

List<String> _bandLabels() => [
  for (final (index, limit) in suspiciousBandsDegrees.indexed)
    index == 0
        ? '< ${_number(limit)}°'
        : '${_number(suspiciousBandsDegrees[index - 1])}–${_number(limit)}°',
];

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
  final median = _medianStwOf(suspicious);
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
    _minutes(side),
    for (final (index, limit) in suspiciousBandsDegrees.indexed)
      _minutes(
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

typedef _SeasonSource = ({int season, PolarSampleSource source});

List<_SeasonSource> _seasonSourcesOf(List<LabSample> samples) {
  final seasons = {for (final sample in samples) sample.season}.toList()
    ..sort();
  return [
    for (final season in seasons)
      for (final source in PolarSampleSource.values)
        if (samples.any(
          (sample) => sample.season == season && sample.source == source,
        ))
          (season: season, source: source),
  ];
}

String _sourceLabel(PolarSampleSource source) => switch (source) {
  PolarSampleSource.telemetry => 'telemetria',
  PolarSampleSource.legacyTrack => 'régi napló',
};

int _minutes(Iterable<LabSample> samples) =>
    (samples.fold(0, (sum, sample) => sum + sample.seconds) / 60).round();

// Az időre súlyozott alsó medián, vagy `null`, ha nincs minta.
double? _medianStwOf(List<LabSample> samples) {
  if (samples.isEmpty) return null;
  final sorted = [...samples]..sort((a, b) => a.stwKnots.compareTo(b.stwKnots));
  final total = sorted.fold(0, (sum, sample) => sum + sample.seconds);
  var cumulative = 0;
  for (final sample in sorted) {
    cumulative += sample.seconds;
    if (cumulative * 2 >= total) return sample.stwKnots;
  }
  return sorted.last.stwKnots;
}

// Az egész szám tizedes nélkül (`15`), a tört egy tizedessel (`2.5`).
String _number(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
