import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

/// Egy nyers rács-cella: a mért idő és a vízsebesség időre súlyozott 90.
/// percentilise (ADR 0058 D2, D7 1.).
@immutable
final class RawPolarCell extends Equatable {
  /// Cella a mért idővel és a p90-nel.
  const RawPolarCell({required this.seconds, required this.p90Knots});

  /// A cella mért ideje másodpercben.
  final int seconds;

  /// A vízsebesség időre súlyozott 90. percentilise csomóban.
  final double p90Knots;

  @override
  List<Object?> get props => [seconds, p90Knots];
}

/// A szűrt minták nyers rácsa a [PolarBuildAxes] tengelyein (ADR 0058 D7
/// 1.): cellánként a mért idő és az STW időre súlyozott p90-e.
///
/// A p90 pontos súlyozott percentilis: a legkisebb vízsebesség, amelynél a
/// nála nem gyorsabb minták ideje eléri a cella idejének 90%-át. A riport
/// rácsa (`PolarGrid`) 0,05 csomós résekkel közelít; itt nincs rés, mert a
/// polár értéke ebből lesz.
///
/// A no-go sorokba és a legkisebb oszlop alá eső minta kimarad; ezeket a
/// `PolarBuildRejection` már előtte kiszűri.
@immutable
final class RawPolarGrid {
  /// A rács a [samples]-ből, az [axes] tengelyein.
  factory RawPolarGrid.of(
    Iterable<LabSample> samples, {
    required PolarBuildAxes axes,
  }) {
    final columnCount = axes.twsColumnsKnots.length;
    final buckets = [
      for (var row = 0; row < PolarBuildAxes.twaRowCount; row++)
        [for (var column = 0; column < columnCount; column++) <_Weighted>[]],
    ];
    for (final sample in samples) {
      final row = PolarBuildAxes.twaRowOf(sample.absTwaDeg);
      final column = axes.twsColumnOf(sample.twsKnots);
      if (column == null) continue;
      if (row < PolarBuildAxes.firstSailingTwaRow) continue;
      if (row >= PolarBuildAxes.twaRowCount) continue;
      buckets[row][column].add((
        knots: sample.stwKnots,
        seconds: sample.seconds,
      ));
    }
    return RawPolarGrid._(
      axes: axes,
      cells: [
        for (final row in buckets)
          List<RawPolarCell?>.unmodifiable(row.map(_cellOf)),
      ],
    );
  }

  const RawPolarGrid._({
    required this.axes,
    required List<List<RawPolarCell?>> cells,
  }) : _cells = cells;

  /// A percentilis, amely a cella értéke.
  static const double percentile = 0.9;

  /// A rács tengelyei.
  final PolarBuildAxes axes;

  final List<List<RawPolarCell?>> _cells;

  /// A [row] TWA-sor és a [column] TWS-oszlop cellája, vagy `null`, ha
  /// nincs benne minta.
  RawPolarCell? cellAt(int row, int column) => _cells[row][column];
}

typedef _Weighted = ({double knots, int seconds});

RawPolarCell? _cellOf(List<_Weighted> samples) {
  if (samples.isEmpty) return null;
  final sorted = [...samples]..sort((a, b) => a.knots.compareTo(b.knots));
  final total = sorted.fold(0, (sum, sample) => sum + sample.seconds);
  final threshold = RawPolarGrid.percentile * total;
  var cumulative = 0;
  for (final sample in sorted) {
    cumulative += sample.seconds;
    if (cumulative >= threshold) {
      return RawPolarCell(seconds: total, p90Knots: sample.knots);
    }
  }
  // Elvileg elérhetetlen: az utolsó mintánál a kumulált idő a teljes idő.
  return RawPolarCell(seconds: total, p90Knots: sorted.last.knots);
}
