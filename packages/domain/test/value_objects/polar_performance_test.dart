import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Teljesitmeny csak hisztogrammal: a mert ido a hisztogram osszege.
PolarPerformance withHistogram(Map<int, int> histogram) => PolarPerformance(
  measuredSeconds: histogram.values.fold(0, (sum, seconds) => sum + seconds),
  pctSecondsSum: 0,
  twsMpsSecondsSum: 0,
  histogram: histogram,
  buckets: const {},
);

void main() {
  group('PolarPerformance averages', () {
    test('divide the sums by the measured time', () {
      // Given
      final performance = PolarPerformance(
        measuredSeconds: 4,
        pctSecondsSum: 360,
        twsMpsSecondsSum: 20,
        histogram: const {180: 4},
        buckets: const {},
      );

      // Then
      expect(performance.averagePct, 90);
      expect(performance.averageTwsMps, 5);
    });

    test('are missing without measured time', () {
      expect(PolarPerformance.empty.averagePct, isNull);
      expect(PolarPerformance.empty.averageTwsMps, isNull);
      expect(PolarPerformance.empty.percentilePct(0.5), isNull);
      expect(PolarPerformance.empty.shareAtOrAbove(90), isNull);
    });
  });

  group('PolarPerformance.hasEnoughData', () {
    test('needs sixty measured seconds', () {
      expect(withHistogram(const {180: 59}).hasEnoughData, isFalse);
      expect(withHistogram(const {180: 60}).hasEnoughData, isTrue);
    });
  });

  group('PolarPerformance.percentilePct', () {
    // 10 mp 90%-on, 80 mp 95%-on, 10 mp 100%-on.
    final performance = withHistogram(const {180: 10, 190: 80, 200: 10});

    test('reports the middle of the bin reaching the rank', () {
      expect(performance.percentilePct(0.5), 95.25);
      expect(performance.percentilePct(0.9), 95.25);
      expect(performance.percentilePct(0.99), 100.25);
    });

    test('is not pushed up by a floating point product', () {
      // Given: 0,07 x 100 = 7,000...01, de a 7. masodperc a 10-es resben
      final split = withHistogram(const {10: 7, 20: 93});

      // Then
      expect(split.percentilePct(0.07), 5.25);
    });

    test('reports the overflow bin as 300 percent', () {
      expect(withHistogram(const {600: 5}).percentilePct(0.5), 300);
    });
  });

  group('PolarPerformance.shareAtOrAbove', () {
    test('counts the seconds from the threshold bin up', () {
      // Given: 10 mp 89%-on, 20 mp 90%-on, 30 mp 100%-on, 40 mp 300% folott
      final performance = withHistogram(const {
        178: 10,
        180: 20,
        200: 30,
        600: 40,
      });

      // Then
      expect(performance.shareAtOrAbove(90), 0.9);
      expect(performance.shareAtOrAbove(100), 0.7);
    });
  });

  group('PolarBucket', () {
    test('adds up and averages', () {
      // Given
      const bucket = PolarBucket(seconds: 2, pctSecondsSum: 180);

      // When
      final sum = bucket + const PolarBucket(seconds: 2, pctSecondsSum: 220);

      // Then
      expect(sum, const PolarBucket(seconds: 4, pctSecondsSum: 400));
      expect(sum.averagePct, 100);
      expect(
        const PolarBucket(seconds: 0, pctSecondsSum: 0).averagePct,
        isNull,
      );
    });
  });
}
