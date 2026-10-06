import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';

// A domain-teljesítmény → a szerződés mutatói (ADR 0049 D8, D11,
// Addendum 4 U7, U8). Pure függvények.

/// A [performance] mutatói; `null`, ha 60 mp-nél kevesebb a mért idő
/// (D8).
PolarStats? polarStatsOf(PolarPerformance performance) {
  if (!performance.hasEnoughData) return null;
  // A `!`-ek biztonságosak: 60 mért másodperctől minden átlag,
  // percentilis és arány értelmezett.
  return PolarStats(
    measuredSeconds: performance.measuredSeconds,
    avgTwsMps: performance.averageTwsMps,
    avgPct: performance.averagePct!,
    medianPct: performance.percentilePct(0.5)!,
    p90Pct: performance.percentilePct(0.9)!,
    p99Pct: performance.percentilePct(0.99)!,
    bestFivePct: performance.bestFiveSecondsPct,
    shareAtLeast90: performance.shareAtOrAbove(90)!,
    shareAtLeast100: performance.shareAtOrAbove(100)!,
  );
}

/// A futamok átlaga sor (D11, U8): a [races] mutatóinak számtani átlaga;
/// `null`, ha üres.
///
/// A legjobb 5 mp a meglévő értékek átlaga; a szél nem átlagolódik. A
/// mért idő az összeg.
PolarStats? raceAverageOf(List<PolarStats> races) {
  if (races.isEmpty) return null;
  double mean(double Function(PolarStats stats) value) =>
      races.fold<double>(0, (sum, stats) => sum + value(stats)) / races.length;
  final bestRuns = [
    for (final stats in races)
      if (stats.bestFivePct case final double best) best,
  ];
  return PolarStats(
    measuredSeconds: races.fold(0, (sum, stats) => sum + stats.measuredSeconds),
    avgPct: mean((stats) => stats.avgPct),
    medianPct: mean((stats) => stats.medianPct),
    p90Pct: mean((stats) => stats.p90Pct),
    p99Pct: mean((stats) => stats.p99Pct),
    bestFivePct: bestRuns.isEmpty
        ? null
        : bestRuns.reduce((sum, best) => sum + best) / bestRuns.length,
    shareAtLeast90: mean((stats) => stats.shareAtLeast90),
    shareAtLeast100: mean((stats) => stats.shareAtLeast100),
  );
}
