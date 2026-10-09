import 'package:domain/src/value_objects/polar_performance.dart';
import 'package:domain/src/value_objects/polar_performance_rules.dart';
import 'package:domain/src/value_objects/polar_ranking.dart';
import 'package:meta/meta.dart';

/// Egy szezon versenyeinek rangja a szezon széleloszlására standardizált
/// %-átlag szerint (ADR 0049 D9, Addendum 3 T6).
///
/// - **Súly:** `w(b)` a rangsorolható versenyek `b` szélvödrébe eső
///   másodpercei.
/// - **Vödör-átlag:** `m(r, b)` a verseny `b` vödrének %-átlaga, ha
///   legalább [PolarPerformanceRules.minimumBucketSeconds] esik oda.
/// - **Standardizált átlag:** `S(r) = Σ w(b)·m(r, b) / Σ w(b)` a verseny
///   érvényes vödrein.
///
/// A [PolarPerformanceRules.minimumSeconds] alatti verseny nem kap rangot
/// és a súlyokba sem számít; érvényes vödör nélkül sincs rang. Az egyenlő
/// `S` (1e-9 tűréssel) egyenlő rangot kap, a következő rang kihagyja a
/// helyet (1, 1, 3).
///
/// **Pure use case**: nincs állapot.
@immutable
class RankPolarPerformance {
  /// Állapotmentes, ezért `const`.
  const RankPolarPerformance();

  // Ennél kisebb S-eltérés döntetlen.
  static const double _tieTolerance = 1e-9;

  /// A [performances] (versenyazonosító → teljesítmény) rangsora.
  PolarRanking call(Map<String, PolarPerformance> performances) {
    final eligible = {
      for (final MapEntry(key: raceId, value: performance)
          in performances.entries)
        if (performance.hasEnoughData) raceId: performance,
    };
    final weights = _bucketWeights(eligible.values);
    final scores = <({String raceId, double score})>[];
    for (final MapEntry(key: raceId, value: performance) in eligible.entries) {
      final score = _standardizedScore(performance, weights);
      if (score != null) scores.add((raceId: raceId, score: score));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));

    final ranks = <String, int>{};
    var rank = 0;
    for (final (index, entry) in scores.indexed) {
      // Egyenlő S az előző rangját kapja; különben a helyezése (1, 1, 3).
      // A tűrés a lebegőpontos összegzés egy ulp-nyi eltérését nyeli el.
      final isTie =
          index > 0 &&
          (entry.score - scores[index - 1].score).abs() < _tieTolerance;
      if (!isTie) rank = index + 1;
      ranks[entry.raceId] = rank;
    }
    return PolarRanking(ranks);
  }

  Map<int, int> _bucketWeights(Iterable<PolarPerformance> performances) {
    final weights = <int, int>{};
    for (final performance in performances) {
      for (final MapEntry(key: index, value: bucket)
          in performance.buckets.entries) {
        weights.update(
          index,
          (value) => value + bucket.seconds,
          ifAbsent: () => bucket.seconds,
        );
      }
    }
    return weights;
  }

  // Az S(r), vagy `null`, ha a versenynek nincs érvényes vödre.
  double? _standardizedScore(
    PolarPerformance performance,
    Map<int, int> weights,
  ) {
    var weightedSum = 0.0;
    var weightSum = 0;
    for (final MapEntry(key: index, value: bucket)
        in performance.buckets.entries) {
      final average = bucket.averagePct;
      final isValid =
          bucket.seconds >= PolarPerformanceRules.minimumBucketSeconds;
      if (!isValid || average == null) continue;
      // A súly a verseny saját vödrét is tartalmazza, tehát nem nulla.
      final weight = weights[index] ?? 0;
      weightedSum += weight * average;
      weightSum += weight;
    }
    return weightSum == 0 ? null : weightedSum / weightSum;
  }
}
