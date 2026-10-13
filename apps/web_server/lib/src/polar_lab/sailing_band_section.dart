import 'package:domain/domain.dart';
import 'package:web_server/src/polar_lab/lab_performance.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// A szezononkénti teljesítmény menetszög és szélsáv szerint
/// (`docs/PLAN.md` P.1b), markdown-szakaszként.
///
/// Csak a 4–16 csomós szél számít, ahol a mai polár cellái bőven mintázottak:
/// így a gyenge szél (ahol a cél a polár tengelyének széléről jön) nem
/// keveredik a szezonok összevetésébe. A cella a medián % és a mért óra; a
/// [PolarPerformanceRules.minimumBucketSeconds] alatti cella üres.
///
/// Pure függvény.
String sailingBandSection({
  required String title,
  required String note,
  required List<LabSample> samples,
  required Polar polar,
}) {
  final columns = [
    for (final sail in _Sail.values)
      for (final band in _bands) (sail: sail, band: band),
  ];
  final buffer = StringBuffer()
    ..writeln('## $title')
    ..writeln()
    ..writeln(note)
    ..writeln()
    ..writeln(
      '| Szezon | ${[for (final column in columns) _labelOf(column)].join(' | ')} |',
    )
    ..writeln('|---|${List.filled(columns.length, '---').join('|')}|');
  final seasons = {for (final sample in samples) sample.season}.toList()
    ..sort();
  for (final season in seasons) {
    final cells = [
      for (final column in columns)
        _cellOf(samples, polar, season: season, column: column),
    ];
    buffer.writeln('| $season | ${cells.join(' | ')} |');
  }
  return (buffer..writeln()).toString();
}

/// A menetszög a `|TWA|` szerint.
enum _Sail {
  upwind('Kreuz'),
  reaching('Félszél'),
  downwind('Hátszél')
  ;

  const _Sail(this.label);

  final String label;

  static _Sail of(double absTwaDeg) => absTwaDeg < 60
      ? upwind
      : absTwaDeg < 120
      ? reaching
      : downwind;
}

typedef _Band = ({int fromKnots, int toKnots});

typedef _Column = ({_Sail sail, _Band band});

const List<_Band> _bands = [
  (fromKnots: 4, toKnots: 8),
  (fromKnots: 8, toKnots: 12),
  (fromKnots: 12, toKnots: 16),
];

String _labelOf(_Column column) =>
    '${column.sail.label} ${column.band.fromKnots}–${column.band.toKnots}';

String _cellOf(
  List<LabSample> samples,
  Polar polar, {
  required int season,
  required _Column column,
}) {
  final weighted = <WeightedPct>[
    for (final sample in samples)
      if (sample.season == season &&
          _Sail.of(sample.absTwaDeg) == column.sail &&
          sample.twsKnots >= column.band.fromKnots &&
          sample.twsKnots < column.band.toKnots)
        if (performancePctOf(sample, polar) case final double pct)
          (pct: pct, seconds: sample.seconds),
  ]..sort((a, b) => a.pct.compareTo(b.pct));
  final seconds = weighted.fold(0, (sum, entry) => sum + entry.seconds);
  if (seconds < PolarPerformanceRules.minimumBucketSeconds) return '·';
  final median = weightedQuantile(weighted, 0.5).toStringAsFixed(1);
  return '$median (${(seconds / 3600).toStringAsFixed(1)})';
}
