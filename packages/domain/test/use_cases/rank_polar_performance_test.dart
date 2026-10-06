import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Teljesitmeny szelvodrokbol: vodor -> (masodperc, %-atlag). A mert ido a
// vodrok osszege; a rang a hisztogramot nem nezi.
PolarPerformance withBuckets(Map<int, (int, double)> buckets) {
  var measuredSeconds = 0;
  var pctSecondsSum = 0.0;
  for (final (seconds, averagePct) in buckets.values) {
    measuredSeconds += seconds;
    pctSecondsSum += seconds * averagePct;
  }
  return PolarPerformance(
    measuredSeconds: measuredSeconds,
    pctSecondsSum: pctSecondsSum,
    twsMpsSecondsSum: 0,
    histogram: const {},
    buckets: {
      for (final MapEntry(key: index, value: (seconds, averagePct))
          in buckets.entries)
        index: PolarBucket(
          seconds: seconds,
          pctSecondsSum: seconds * averagePct,
        ),
    },
  );
}

void main() {
  const rank = RankPolarPerformance();

  group('RankPolarPerformance', () {
    test('ranks by the average standardized to the season wind', () {
      // Given: a sulyok 4-6 kn: 100 + 300 = 400 mp, 10-12 kn: 100 + 60 mp
      final performances = {
        // S = (400 x 90 + 160 x 100) / 560 = 92,86
        'a': withBuckets({2: (100, 90), 5: (100, 100)}),
        // S = 95: csak a gyenge szel
        'b': withBuckets({2: (300, 95)}),
        // S = 92: csak az eros szel
        'c': withBuckets({5: (60, 92)}),
      };

      // When
      final ranking = rank(performances);

      // Then
      expect(ranking.ranks, {'b': 1, 'a': 2, 'c': 3});
      expect(ranking.rankedCount, 3);
    });

    test('leaves out a race below sixty seconds, also from the weights', () {
      // Given: a 'd' 50 mp-e kimarad; ha a sulyba szamitana, a 4-6 kn-os
      // vodor sulya 450 lenne
      final performances = {
        'a': withBuckets({2: (100, 90), 5: (100, 100)}),
        'c': withBuckets({5: (60, 92)}),
        'd': withBuckets({2: (50, 200)}),
      };

      // When
      final ranking = rank(performances);

      // Then: S(a) = (100 x 90 + 160 x 100) / 260 = 96,15 > 92
      expect(ranking.rankOf('d'), isNull);
      expect(ranking.ranks, {'a': 1, 'c': 2});
    });

    test('ignores a wind bucket below sixty seconds', () {
      // Given: a 4-6 kn-os vodor csak 59 mp, a 200%-a nem szamit
      final performances = {
        'x': withBuckets({2: (59, 200), 5: (100, 80)}),
        'y': withBuckets({5: (100, 85)}),
      };

      // When
      final ranking = rank(performances);

      // Then
      expect(ranking.ranks, {'y': 1, 'x': 2});
    });

    test('gives no rank without a valid wind bucket', () {
      // Given: 80 mp, de egyik vodorben sincs 60
      final ranking = rank({
        'split': withBuckets({2: (40, 100), 5: (40, 100)}),
      });

      // Then
      expect(ranking.rankOf('split'), isNull);
      expect(ranking.rankedCount, 0);
    });

    test('shares a rank on equal scores and skips the next one', () {
      // Given
      final performances = {
        'first': withBuckets({5: (100, 95)}),
        'twin': withBuckets({5: (100, 95)}),
        'third': withBuckets({5: (100, 90)}),
      };

      // When
      final ranking = rank(performances);

      // Then
      expect(ranking.ranks, {'first': 1, 'twin': 1, 'third': 3});
    });
  });
}
