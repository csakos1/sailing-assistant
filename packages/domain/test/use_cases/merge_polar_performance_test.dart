import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const merge = MergePolarPerformance();

  final first = PolarPerformance(
    measuredSeconds: 3,
    pctSecondsSum: 270,
    twsMpsSecondsSum: 15,
    histogram: const {180: 3},
    buckets: const {5: PolarBucket(seconds: 3, pctSecondsSum: 270)},
    bestFiveSecondsPct: 95,
  );
  final second = PolarPerformance(
    measuredSeconds: 2,
    pctSecondsSum: 200,
    twsMpsSecondsSum: 8,
    histogram: const {180: 1, 220: 1},
    buckets: const {
      4: PolarBucket(seconds: 1, pctSecondsSum: 110),
      5: PolarBucket(seconds: 1, pctSecondsSum: 90),
    },
  );

  group('MergePolarPerformance', () {
    test('adds up sums, histograms and wind buckets', () {
      // When
      final merged = merge([first, second]);

      // Then
      expect(merged.measuredSeconds, 5);
      expect(merged.pctSecondsSum, 470);
      expect(merged.twsMpsSecondsSum, 23);
      expect(merged.histogram, {180: 4, 220: 1});
      expect(merged.buckets, {
        4: const PolarBucket(seconds: 1, pctSecondsSum: 110),
        5: const PolarBucket(seconds: 4, pctSecondsSum: 360),
      });
    });

    test('keeps the best five seconds of all races', () {
      expect(merge([second, first]).bestFiveSecondsPct, 95);
      expect(merge([second]).bestFiveSecondsPct, isNull);
    });

    test('gives an empty performance for no races', () {
      expect(merge(const []), PolarPerformance.empty);
    });
  });
}
