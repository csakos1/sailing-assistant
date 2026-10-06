import 'package:domain/src/value_objects/polar_bucket.dart';
import 'package:domain/src/value_objects/polar_performance_rules.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Egy futam (vagy több futam összege) polár-teljesítménye (ADR 0049 D8,
/// D10, Addendum 3 T5).
///
/// Csak összegeket és eloszlásokat tárol, hogy a futamok összevonhatók
/// legyenek (D11): az átlag, a percentilis és az arányok ezekből jönnek.
/// A `%` a korrigált STW és a polár cél-STW-jének hányadosa, százszorosan.
@immutable
class PolarPerformance extends Equatable {
  /// Teljesítmény a megadott összegekkel és eloszlásokkal.
  PolarPerformance({
    required this.measuredSeconds,
    required this.pctSecondsSum,
    required this.twsMpsSecondsSum,
    required Map<int, int> histogram,
    required Map<int, PolarBucket> buckets,
    this.bestFiveSecondsPct,
  }) : histogram = Map.unmodifiable(histogram),
       buckets = Map.unmodifiable(buckets);

  /// Üres teljesítmény: egyetlen polár-minta sincs.
  static final PolarPerformance empty = PolarPerformance(
    measuredSeconds: 0,
    pctSecondsSum: 0,
    twsMpsSecondsSum: 0,
    histogram: const {},
    buckets: const {},
  );

  /// A polár-minták másodperceinek összege.
  final int measuredSeconds;

  /// A `% × másodperc` szorzatok összege.
  final double pctSecondsSum;

  /// A `TWS (m/s) × másodperc` szorzatok összege.
  final double twsMpsSecondsSum;

  /// A %-hisztogram: rés → másodperc, csak a nem üres rések. A rés
  /// `floor(2 × %)`, a 300% fölötti másodpercek a
  /// [PolarPerformanceRules.overflowBin] résben.
  final Map<int, int> histogram;

  /// A szélvödrök: `floor(TWS csomó / 2)` → összegek.
  final Map<int, PolarBucket> buckets;

  /// Öt egymást követő másodperc %-átlagának maximuma; `null`, ha nincs
  /// ilyen futam (például a régi, 10 mp-es mintáknál).
  final double? bestFiveSecondsPct;

  /// Igaz, ha a mért idő eléri a [PolarPerformanceRules.minimumSeconds]-ot.
  bool get hasEnoughData =>
      measuredSeconds >= PolarPerformanceRules.minimumSeconds;

  /// A %-ok időre súlyozott átlaga; `null` mért idő nélkül.
  double? get averagePct =>
      measuredSeconds == 0 ? null : pctSecondsSum / measuredSeconds;

  /// A TWS időre súlyozott átlaga m/s-ben; `null` mért idő nélkül.
  double? get averageTwsMps =>
      measuredSeconds == 0 ? null : twsMpsSecondsSum / measuredSeconds;

  /// A [fraction] (0–1] percentilis százalékban, a hisztogramból.
  ///
  /// A legkisebb rés, ahol a kumulált másodperc eléri a
  /// `ceil(fraction × N)`-t, a rés közepével (±0,25%-pont); a túlcsorduló
  /// rés 300%-ot ad. Mért idő nélkül `null`.
  double? percentilePct(double fraction) {
    assert(fraction > 0 && fraction <= 1, 'A percentilis (0, 1] között.');
    if (measuredSeconds == 0) return null;
    // A kis epszilon a lebegőpontos szorzat felfelé csúszását fogja meg:
    // a 0,07 × 100 = 7,000…01 különben 8-ra kerekedne.
    final target = (fraction * measuredSeconds - 1e-9).ceil();
    var cumulative = 0;
    for (final bin in _sortedBins) {
      cumulative += histogram[bin] ?? 0;
      if (cumulative >= target) return _binValuePct(bin);
    }
    // A hisztogram összege a mért idő, ezért ide nem jutunk; védőháló.
    return _binValuePct(_sortedBins.last);
  }

  /// A legalább [percent] %-os másodpercek aránya (0–1); `null` mért idő
  /// nélkül.
  ///
  /// Pontos, mert a [percent] rés-határ: fél százalékpontra kerek kell
  /// legyen (például 90 vagy 100).
  double? shareAtOrAbove(double percent) {
    final firstBin = percent * PolarPerformanceRules.binsPerPercent;
    assert(
      firstBin == firstBin.roundToDouble(),
      'A küszöb rés-határ: fél százalékpontra kerek.',
    );
    if (measuredSeconds == 0) return null;
    var seconds = 0;
    for (final MapEntry(key: bin, value: binSeconds) in histogram.entries) {
      if (bin >= firstBin) seconds += binSeconds;
    }
    return seconds / measuredSeconds;
  }

  List<int> get _sortedBins => histogram.keys.toList()..sort();

  static double _binValuePct(int bin) =>
      bin >= PolarPerformanceRules.overflowBin
      ? PolarPerformanceRules.overflowPercent.toDouble()
      : (bin + 0.5) / PolarPerformanceRules.binsPerPercent;

  @override
  List<Object?> get props => [
    measuredSeconds,
    pctSecondsSum,
    twsMpsSecondsSum,
    histogram,
    buckets,
    bestFiveSecondsPct,
  ];
}
