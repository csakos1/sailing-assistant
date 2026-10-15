import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/lab_sample_tables.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';

/// A polár-összesítő diagnosztikai szakasza a mély hátszeles VMG-szűrőhöz
/// (`PolarBuildRejection.downwindVmg`, `docs/PLAN.md` P.3).
///
/// A [samples] a VMG-szűrő előtti minták (minden más szűrő után). A szakasz
/// a mély hátszél (`|TWA|` ≥ [PolarBuildRejection.deepDownwindTwaDegrees])
/// legfeljebb [deepDownwindMaximumColumnKnots] csomós oszlopainak idejét
/// mutatja a VMG/TWS arány sávjai ([downwindRatioBands]) szerint,
/// szezononként és forrásonként, valamint TWS-oszloponként, és a
/// [maximumRatio] fölötti (kidobott) minták vízsebességének mediánját.
/// Csak összesített számokat ír.
///
/// Pure függvény.
String deepDownwindSection(
  List<LabSample> samples, {
  required PolarBuildAxes axes,
  required double maximumRatio,
}) {
  final scope = [
    for (final sample in samples)
      if (_isInScope(sample, axes)) sample,
  ];
  final buffer = StringBuffer()
    ..writeln('## 8. Mély hátszél: VMG a szélhez mérve')
    ..writeln()
    ..writeln(
      'Mély hátszél (`|TWA|` ≥ '
      '${tableNumber(PolarBuildRejection.deepDownwindTwaDegrees)}°), '
      'legfeljebb ${tableNumber(deepDownwindMaximumColumnKnots)} kn-os '
      'oszlop, a VMG-szűrő előtt (minden más szűrő után), perc. A VMG = '
      'STW × |cos TWA|; az arány a VMG és a TWS hányadosa. A szűrő '
      'küszöbe: ${tableNumber(maximumRatio)}, e fölött dob; az utolsó '
      'oszlop a kidobott minták STW-mediánja.',
    )
    ..writeln()
    ..writeln('### Szezon és forrás szerint')
    ..writeln()
    ..writeln('| Szezon | Forrás ${_header()}')
    ..writeln('|---|---${_separator()}');
  for (final (:season, :source) in seasonSourcesOf(scope)) {
    final group = [
      for (final sample in scope)
        if (sample.season == season && sample.source == source) sample,
    ];
    buffer.writeln(
      '| $season | ${sourceLabelOf(source)} ${_cells(group, maximumRatio)}',
    );
  }
  buffer
    ..writeln()
    ..writeln('### TWS-oszlop szerint (minden szezon)')
    ..writeln()
    ..writeln('| TWS ${_header()}')
    ..writeln('|---${_separator()}');
  for (final (column, knots) in axes.twsColumnsKnots.indexed) {
    if (knots > deepDownwindMaximumColumnKnots) continue;
    final group = [
      for (final sample in scope)
        if (axes.twsColumnOf(sample.twsKnots) == column) sample,
    ];
    buffer.writeln('| ${tableNumber(knots)} ${_cells(group, maximumRatio)}');
  }
  return (buffer..writeln()).toString();
}

/// A VMG/TWS arány sávjainak felső határai, növekvő sorrendben; az utolsó
/// sáv nyitott felfelé.
const List<double> downwindRatioBands = [1, 1.3, 1.6];

/// A szakasz legnagyobb TWS-oszlopa csomóban: a gyenge szél és egy
/// összehasonlító, megbízható szélerő.
const double deepDownwindMaximumColumnKnots = 8;

bool _isInScope(LabSample sample, PolarBuildAxes axes) {
  if (sample.absTwaDeg < PolarBuildRejection.deepDownwindTwaDegrees) {
    return false;
  }
  final column = axes.twsColumnOf(sample.twsKnots);
  return column != null &&
      axes.twsColumnsKnots[column] <= deepDownwindMaximumColumnKnots;
}

List<String> _bandLabels() => [
  '< ${tableNumber(downwindRatioBands.first)}',
  for (var index = 1; index < downwindRatioBands.length; index++)
    _rangeLabel(index),
  '≥ ${tableNumber(downwindRatioBands.last)}',
];

String _rangeLabel(int index) {
  final lower = tableNumber(downwindRatioBands[index - 1]);
  final upper = tableNumber(downwindRatioBands[index]);
  return '$lower–$upper';
}

String _header() =>
    '| Perc | ${_bandLabels().join(' | ')} | STW-medián a küszöb fölött (kn) |';

// A fejléc oszlopai: összesen, a sávok és a medián.
String _separator() {
  final columns = 1 + downwindRatioBands.length + 1 + 1;
  return '${'|---' * columns}|';
}

String _cells(List<LabSample> group, double maximumRatio) {
  final dropped = [
    for (final sample in group)
      if (PolarBuildRejection.downwindVmgRatioOf(sample) > maximumRatio) sample,
  ];
  final median = weightedMedianStwOf(dropped);
  final cells = <Object>[
    minutesOf(group),
    for (var band = 0; band <= downwindRatioBands.length; band++)
      minutesOf(group.where((sample) => _bandOf(sample) == band)),
    if (median == null) '·' else median.toStringAsFixed(2),
  ];
  return '| ${cells.join(' | ')} |';
}

// A minta sávjának indexe: az első határ alatt 0, az utolsó fölött a sávok
// száma.
int _bandOf(LabSample sample) {
  final ratio = PolarBuildRejection.downwindVmgRatioOf(sample);
  for (final (index, limit) in downwindRatioBands.indexed) {
    if (ratio < limit) return index;
  }
  return downwindRatioBands.length;
}
