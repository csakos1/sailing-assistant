import 'package:domain/src/value_objects/polar_bucket.dart';
import 'package:domain/src/value_objects/polar_performance.dart';
import 'package:meta/meta.dart';

/// Több futam polár-teljesítményének összege (ADR 0049 D11, Addendum 3
/// T6).
///
/// Az összegek, a hisztogramok és a szélvödrök összeadódnak, így az
/// eredmény az időre súlyozott szezon-sor. A legjobb 5 mp a futamok
/// maximuma.
///
/// **Pure use case**: nincs állapot; a sorrend nem számít.
@immutable
class MergePolarPerformance {
  /// Állapotmentes, ezért `const`.
  const MergePolarPerformance();

  /// A [performances] összege; üres bemenetre [PolarPerformance.empty].
  PolarPerformance call(Iterable<PolarPerformance> performances) {
    var measuredSeconds = 0;
    var pctSecondsSum = 0.0;
    var twsMpsSecondsSum = 0.0;
    final histogram = <int, int>{};
    final buckets = <int, PolarBucket>{};
    double? bestFiveSecondsPct;
    for (final performance in performances) {
      measuredSeconds += performance.measuredSeconds;
      pctSecondsSum += performance.pctSecondsSum;
      twsMpsSecondsSum += performance.twsMpsSecondsSum;
      for (final MapEntry(key: bin, value: seconds)
          in performance.histogram.entries) {
        histogram.update(
          bin,
          (value) => value + seconds,
          ifAbsent: () => seconds,
        );
      }
      for (final MapEntry(key: index, value: bucket)
          in performance.buckets.entries) {
        buckets.update(
          index,
          (value) => value + bucket,
          ifAbsent: () => bucket,
        );
      }
      final best = performance.bestFiveSecondsPct;
      if (best != null &&
          (bestFiveSecondsPct == null || best > bestFiveSecondsPct)) {
        bestFiveSecondsPct = best;
      }
    }
    return PolarPerformance(
      measuredSeconds: measuredSeconds,
      pctSecondsSum: pctSecondsSum,
      twsMpsSecondsSum: twsMpsSecondsSum,
      histogram: histogram,
      buckets: buckets,
      bestFiveSecondsPct: bestFiveSecondsPct,
    );
  }
}
