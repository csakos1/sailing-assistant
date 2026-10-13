import 'package:meta/meta.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// Egy rács-cella kulcsa: a TWA-sor foka és a TWS-oszlop.
typedef PolarGridKey = ({int twaDeg, int twsColumn});

/// A minták TWA × TWS rácsa (`docs/PLAN.md` P.1): cellánként a mért idő és
/// a vízsebesség időre súlyozott eloszlása.
///
/// A TWA-sor a `|TWA|` [twaStepDegrees]-ra kerekítve, mert a `.pol` sorai
/// is 5°-osak. A TWS-oszlop 1 csomós vödör az alsó határával: a 3-as oszlop
/// a [3, 4) csomó. A [maxTwsColumn] fölötti szél a legfelső oszlopba kerül.
/// A vízsebesség [stwBinKnots] széles résekben gyűlik, a percentilis a rés
/// közepét adja.
@immutable
final class PolarGrid {
  /// A rács a [samples]-ből.
  factory PolarGrid.of(Iterable<LabSample> samples) {
    final cells = <PolarGridKey, Map<int, int>>{};
    for (final sample in samples) {
      final key = keyOf(twaDeg: sample.absTwaDeg, twsKnots: sample.twsKnots);
      final bin = (sample.stwKnots / stwBinKnots).floor();
      cells
          .putIfAbsent(key, () => <int, int>{})
          .update(
            bin,
            (seconds) => seconds + sample.seconds,
            ifAbsent: () => sample.seconds,
          );
    }
    return PolarGrid._({
      for (final MapEntry(:key, :value) in cells.entries)
        key: Map<int, int>.unmodifiable(value),
    });
  }

  const PolarGrid._(this._cells);

  /// A TWA-sorok lépése fokban.
  static const int twaStepDegrees = 5;

  /// A legfelső TWS-oszlop; e fölött minden szél ide kerül.
  static const int maxTwsColumn = 25;

  /// A vízsebesség-eloszlás résszélessége csomóban.
  static const double stwBinKnots = 0.05;

  final Map<PolarGridKey, Map<int, int>> _cells;

  /// A [twaDeg] szög és a [twsKnots] szél cellája.
  static PolarGridKey keyOf({
    required double twaDeg,
    required double twsKnots,
  }) {
    final column = twsKnots.floor();
    return (
      twaDeg: (twaDeg / twaStepDegrees).round() * twaStepDegrees,
      twsColumn: column > maxTwsColumn ? maxTwsColumn : column,
    );
  }

  /// Az adatos TWA-sorok növekvő sorrendben.
  List<int> get twaRows {
    final rows = {for (final key in _cells.keys) key.twaDeg}.toList()..sort();
    return rows;
  }

  /// Az adatos TWS-oszlopok növekvő sorrendben.
  List<int> get twsColumns {
    final columns = {for (final key in _cells.keys) key.twsColumn}.toList()
      ..sort();
    return columns;
  }

  /// A cella mért ideje másodpercben; adat nélkül 0.
  int secondsAt(PolarGridKey key) {
    final histogram = _cells[key];
    if (histogram == null) return 0;
    return histogram.values.fold(0, (sum, seconds) => sum + seconds);
  }

  /// A cella vízsebességének időre súlyozott [fraction] percentilise
  /// (0 < [fraction] ≤ 1) csomóban, vagy `null`, ha a cellában nincs adat.
  double? stwPercentileAt(PolarGridKey key, double fraction) {
    final histogram = _cells[key];
    if (histogram == null || histogram.isEmpty) return null;
    final total = histogram.values.fold(0, (sum, seconds) => sum + seconds);
    final threshold = fraction * total;
    var cumulative = 0;
    final bins = histogram.keys.toList()..sort();
    for (final bin in bins) {
      // A `!` biztonságos: a kulcs a térkép saját kulcsa.
      cumulative += histogram[bin]!;
      if (cumulative >= threshold) return (bin + 0.5) * stwBinKnots;
    }
    return (bins.last + 0.5) * stwBinKnots;
  }
}
