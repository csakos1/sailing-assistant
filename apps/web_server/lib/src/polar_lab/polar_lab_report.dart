import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_grid.dart';

/// A polár-elemzés markdown-riportja (`docs/PLAN.md` P.1).
///
/// Csak összesített számokat ír (szezononkénti idő és teljesítmény,
/// cellánkénti idő és percentilis, VMG-optimum, a polár simasága): nyers
/// minta, időbélyeg, pozíció és versenynév nincs benne, így a riport
/// megosztható. A teljesítmény ugyanaz a `100 × STW / cél-STW`, mint a
/// weben, ugyanazzal a lookuppal (ADR 0049 D5).
///
/// Pure függvény: ugyanarra a bemenetre ugyanazt a szöveget adja.
String polarLabReport({
  required List<LabSample> samples,
  required Polar polar,
  required int focusSeason,
  required String polarLabel,
}) {
  final focus = [
    for (final sample in samples)
      if (sample.season == focusSeason) sample,
  ];
  final focusGrid = PolarGrid.of(focus);
  final allGrid = PolarGrid.of(samples);
  final report = StringBuffer()
    ..writeln('# Polár-riport (P.1)')
    ..writeln()
    ..writeln('Polár: `$polarLabel`. Fókusz-szezon: $focusSeason.')
    ..writeln()
    ..write(_inventorySection(samples))
    ..write(_performanceSection(samples, polar))
    ..write(_gridSection('3. A $focusSeason-es szezon rácsa', focusGrid, polar))
    ..write(_gridSection('4. Minden szezon rácsa', allGrid, polar))
    ..write(_vmgSection(focusSeason, focusGrid, polar))
    ..write(_smoothnessSection(polar));
  return report.toString();
}

const _lookupTargetSpeed = LookupTargetSpeed();

// A cella percentilise csak ennyi mért idő fölött áll (ADR 0049 D10).
const int _minimumCellSeconds = PolarPerformanceRules.minimumBucketSeconds;

const String _empty = '·';

String _inventorySection(List<LabSample> samples) {
  final buffer = StringBuffer()
    ..writeln('## 1. Adatkészlet')
    ..writeln()
    ..writeln(
      '| Szezon | Verseny (telemetria / régi) | Óra | TWS < 4 kn | 4–20 kn | > 20 kn |',
    )
    ..writeln('|---|---|---|---|---|---|');
  for (final season in _seasonsOf(samples)) {
    final ofSeason = [
      for (final sample in samples)
        if (sample.season == season) sample,
    ];
    final telemetry = _raceCountOf(ofSeason, PolarSampleSource.telemetry);
    final legacy = _raceCountOf(ofSeason, PolarSampleSource.legacyTrack);
    final total = _secondsOf(ofSeason);
    final light = _secondsOf(ofSeason.where((sample) => sample.twsKnots < 4));
    final strong = _secondsOf(ofSeason.where((sample) => sample.twsKnots > 20));
    buffer.writeln(
      '| $season | $telemetry / $legacy | ${_hours(total)} | ${_share(light, total)} '
      '| ${_share(total - light - strong, total)} | ${_share(strong, total)} |',
    );
  }
  return (buffer..writeln()).toString();
}

String _performanceSection(List<LabSample> samples, Polar polar) {
  final buffer = StringBuffer()
    ..writeln('## 2. Teljesítmény a mai polárhoz')
    ..writeln()
    ..writeln('A no-go zóna (cél nélkül) kimarad.')
    ..writeln()
    ..writeln('| Szezon | Óra | Átlag % | Medián % | p90 % | ≥ 100% |')
    ..writeln('|---|---|---|---|---|---|');
  for (final season in _seasonsOf(samples)) {
    final weighted = <({double pct, int seconds})>[
      for (final sample in samples)
        if (sample.season == season)
          if (_pctOf(sample, polar) case final double pct)
            (pct: pct, seconds: sample.seconds),
    ];
    if (weighted.isEmpty) continue;
    weighted.sort((a, b) => a.pct.compareTo(b.pct));
    final total = weighted.fold(0, (sum, entry) => sum + entry.seconds);
    final pctSeconds = weighted.fold<double>(
      0,
      (sum, entry) => sum + entry.pct * entry.seconds,
    );
    final atLeastFull = weighted
        .where((entry) => entry.pct >= 100)
        .fold(0, (sum, entry) => sum + entry.seconds);
    buffer.writeln(
      '| $season | ${_hours(total)} | ${(pctSeconds / total).toStringAsFixed(1)} '
      '| ${_weightedQuantile(weighted, total, 0.5).toStringAsFixed(1)} '
      '| ${_weightedQuantile(weighted, total, 0.9).toStringAsFixed(1)} '
      '| ${_share(atLeastFull, total)} |',
    );
  }
  return (buffer..writeln()).toString();
}

String _gridSection(String title, PolarGrid grid, Polar polar) {
  final columns = grid.twsColumns;
  final buffer = StringBuffer()
    ..writeln('## $title')
    ..writeln()
    ..writeln(
      'Sor: `|TWA|` 5°-ra kerekítve; oszlop: TWS-vödör [n, n+1) csomó '
      '(a ${PolarGrid.maxTwsColumn}-ös oszlop a fölötte lévő szél is, ezért ott '
      'a célhoz mért arány üres). '
      'A percentilis $_minimumCellSeconds mp mért idő alatt üres ($_empty).',
    )
    ..writeln()
    ..writeln('### Mért idő (perc)')
    ..writeln()
    ..write(_table(grid, columns, (key) => _minutesCell(grid.secondsAt(key))))
    ..writeln('### Vízsebesség p90 (kn)')
    ..writeln()
    ..write(_table(grid, columns, (key) => _formatOrEmpty(_p90At(grid, key))))
    ..writeln('### p90 a mai polár céljához (%)')
    ..writeln()
    ..write(
      _table(
        grid,
        columns,
        (key) => _formatOrEmpty(_ratioAt(grid, key, polar), 0),
      ),
    );
  return buffer.toString();
}

String _table(
  PolarGrid grid,
  List<int> columns,
  String Function(PolarGridKey key) cellOf,
) {
  final buffer = StringBuffer()
    ..writeln('| TWA \\ TWS | ${columns.join(' | ')} |')
    ..writeln('|---|${List.filled(columns.length, '---').join('|')}|');
  for (final twaDeg in grid.twaRows) {
    final cells = [
      for (final column in columns) cellOf((twaDeg: twaDeg, twsColumn: column)),
    ];
    buffer.writeln('| $twaDeg | ${cells.join(' | ')} |');
  }
  return (buffer..writeln()).toString();
}

String _vmgSection(int focusSeason, PolarGrid grid, Polar polar) {
  final buffer = StringBuffer()
    ..writeln('## 5. VMG-optimum ($focusSeason p90 vs. mai polár)')
    ..writeln()
    ..writeln(
      'A legjobb VMG-t adó `|TWA|` és a VMG (kn); a TWS az oszlop közepe.',
    )
    ..writeln()
    ..writeln(
      '| TWS | Kreuz: adat | Kreuz: polár | Hátszél: adat | Hátszél: polár |',
    )
    ..writeln('|---|---|---|---|---|');
  for (final column in grid.twsColumns) {
    // A felső oszlop nyitott vödör: nincs közepe a polár-lookuphoz.
    if (column >= PolarGrid.maxTwsColumn) continue;
    final twsKnots = column + 0.5;
    String best({required bool isUpwind, required bool fromData}) {
      final optimum = fromData
          ? _dataOptimum(grid, column, isUpwind: isUpwind)
          : _polarOptimum(polar, twsKnots, isUpwind: isUpwind);
      return optimum == null
          ? _empty
          : '${optimum.twaDeg}° / ${optimum.vmgKnots.toStringAsFixed(2)}';
    }

    buffer.writeln(
      '| $column | ${best(isUpwind: true, fromData: true)} '
      '| ${best(isUpwind: true, fromData: false)} '
      '| ${best(isUpwind: false, fromData: true)} '
      '| ${best(isUpwind: false, fromData: false)} |',
    );
  }
  return (buffer..writeln()).toString();
}

String _smoothnessSection(Polar polar) {
  final (:drops, :holes) = _irregularCellsOf(polar);
  final buffer = StringBuffer()
    ..writeln('## 6. A mai polár simasága')
    ..writeln()
    ..writeln(
      'Erősödő szélben csökkenő cél (> $_dropToleranceKnots kn): ${drops.length} hely.',
    )
    ..writeln()
    ..writeAll(drops.map((line) => '- $line\n'))
    ..writeln()
    ..writeln(
      'Üres cella (a no-go fölött): ${holes.length} — ${holes.join(', ')}',
    )
    ..writeln();
  return buffer.toString();
}

// A polár szabálytalan cellái: ahol a cél erősödő szélben csökken, és ahol
// üres (a no-go zóna fölött).
({List<String> drops, List<String> holes}) _irregularCellsOf(Polar polar) {
  final drops = <String>[];
  final holes = <String>[];
  for (final (row, twaDeg) in polar.twaAxis.indexed) {
    if (twaDeg < Polar.noGoThresholdDegrees) continue;
    final cells = polar.grid[row];
    for (final (column, target) in cells.indexed) {
      final twsKnots = _formatKnots(polar.twsAxis[column]);
      if (target == null) {
        holes.add('${_formatKnots(twaDeg)}° @ $twsKnots kn');
        continue;
      }
      final next = column + 1 < cells.length ? cells[column + 1] : null;
      if (next != null && next < target - _dropToleranceKnots) {
        drops.add(
          '${_formatKnots(twaDeg)}°: $twsKnots → ${_formatKnots(polar.twsAxis[column + 1])} kn, '
          '${target.toStringAsFixed(2)} → ${next.toStringAsFixed(2)}',
        );
      }
    }
  }
  return (drops: drops, holes: holes);
}

// A szomszéd-cellák közti, zajnak még nem számító csökkenés.
const double _dropToleranceKnots = 0.1;

typedef _Optimum = ({int twaDeg, double vmgKnots});

_Optimum? _dataOptimum(PolarGrid grid, int column, {required bool isUpwind}) {
  _Optimum? best;
  for (final twaDeg in grid.twaRows) {
    // A no-go sor itt sem jelölt, mint a polárnál.
    if (twaDeg < Polar.noGoThresholdDegrees) continue;
    if (isUpwind ? twaDeg >= 90 : twaDeg <= 90) continue;
    final stw = _p90At(grid, (twaDeg: twaDeg, twsColumn: column));
    if (stw == null) continue;
    final vmg = _vmgOf(stw, twaDeg, isUpwind: isUpwind);
    if (best == null || vmg > best.vmgKnots) {
      best = (twaDeg: twaDeg, vmgKnots: vmg);
    }
  }
  return best;
}

_Optimum? _polarOptimum(
  Polar polar,
  double twsKnots, {
  required bool isUpwind,
}) {
  _Optimum? best;
  for (var twaDeg = 0; twaDeg <= 180; twaDeg += PolarGrid.twaStepDegrees) {
    if (isUpwind ? twaDeg >= 90 : twaDeg <= 90) continue;
    final target = _lookupTargetSpeed(
      polar: polar,
      twaDegrees: twaDeg.toDouble(),
      twsKnots: twsKnots,
    );
    if (target == null) continue;
    final vmg = _vmgOf(target, twaDeg, isUpwind: isUpwind);
    if (best == null || vmg > best.vmgKnots) {
      best = (twaDeg: twaDeg, vmgKnots: vmg);
    }
  }
  return best;
}

// Kreuzban a szél felé, hátszélben a széllel vetített sebesség.
double _vmgOf(double speedKnots, int twaDeg, {required bool isUpwind}) {
  final projection = math.cos(twaDeg * math.pi / 180);
  return speedKnots * (isUpwind ? projection : -projection);
}

double? _p90At(PolarGrid grid, PolarGridKey key) =>
    grid.secondsAt(key) < _minimumCellSeconds
    ? null
    : grid.stwPercentileAt(key, 0.9);

double? _ratioAt(PolarGrid grid, PolarGridKey key, Polar polar) {
  // A felső oszlop nyitott vödör: nincs közepe, amihez a célt mérnénk.
  if (key.twsColumn >= PolarGrid.maxTwsColumn) return null;
  final stw = _p90At(grid, key);
  if (stw == null) return null;
  final target = _lookupTargetSpeed(
    polar: polar,
    twaDegrees: key.twaDeg.toDouble(),
    twsKnots: key.twsColumn + 0.5,
  );
  if (target == null || target <= 0) return null;
  return 100 * stw / target;
}

double? _pctOf(LabSample sample, Polar polar) {
  final target = _lookupTargetSpeed(
    polar: polar,
    twaDegrees: sample.absTwaDeg,
    twsKnots: sample.twsKnots,
  );
  if (target == null || target <= 0) return null;
  return 100 * sample.stwKnots / target;
}

// Az időre súlyozott kvantilis a [sorted] (pct szerint növekvő) listából.
double _weightedQuantile(
  List<({double pct, int seconds})> sorted,
  int total,
  double fraction,
) {
  final threshold = fraction * total;
  var cumulative = 0;
  for (final entry in sorted) {
    cumulative += entry.seconds;
    if (cumulative >= threshold) return entry.pct;
  }
  return sorted.last.pct;
}

List<int> _seasonsOf(List<LabSample> samples) {
  final seasons = {for (final sample in samples) sample.season}.toList()
    ..sort();
  return seasons;
}

int _raceCountOf(List<LabSample> samples, PolarSampleSource source) => {
  for (final sample in samples)
    if (sample.source == source) sample.raceId,
}.length;

int _secondsOf(Iterable<LabSample> samples) =>
    samples.fold(0, (sum, sample) => sum + sample.seconds);

String _hours(int seconds) => (seconds / 3600).toStringAsFixed(1);

String _share(int part, int total) =>
    total == 0 ? _empty : '${(100 * part / total).toStringAsFixed(0)}%';

String _minutesCell(int seconds) =>
    seconds == 0 ? _empty : (seconds / 60).round().toString();

String _formatOrEmpty(double? value, [int fractionDigits = 2]) =>
    value == null ? _empty : value.toStringAsFixed(fractionDigits);

// A tengely-értékek egészek; tizedes csak akkor, ha tényleg van.
String _formatKnots(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
