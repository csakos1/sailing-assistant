import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Csomo -> m/s, ahogy a muszer adja.
double mps(double knots) => knots * 1852 / 3600;

void main() {
  const summarize = SummarizePolarPerformance();

  // Egyszeru polar: minden cellaban 5 kn, igy a % = 20 x STW (kn). A
  // 25 fok alatti |TWA| a no-go zona.
  final polar = Polar(
    twaAxis: const <double>[30, 60, 120],
    twsAxis: const <double>[4, 8, 12, 16, 20],
    grid: [for (var row = 0; row < 3; row++) List<double?>.filled(5, 5)],
  );
  final start = DateTime.utc(2026, 7, 26, 10);

  // Alapertek: TWA 60, TWS 10 kn, STW 4 kn -> 80%, a 160-as res, az 5-os
  // szelvodor.
  PolarSample sample(
    int second, {
    double? twaDeg = 60,
    double? twsKnots = 10,
    double? stwKnots = 4,
    int durationSeconds = 1,
  }) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: twsKnots == null ? null : mps(twsKnots),
    stwMps: stwKnots == null ? null : mps(stwKnots),
    durationSeconds: durationSeconds,
  );

  PolarPerformance run(
    List<PolarSample> samples, {
    List<StwCorrection> corrections = const [],
  }) => summarize(samples: samples, polar: polar, stwCorrections: corrections);

  group('SummarizePolarPerformance sums', () {
    test('the accepted samples into histogram and wind bucket', () {
      // When
      final performance = run([sample(0), sample(1), sample(2)]);

      // Then
      expect(performance.measuredSeconds, 3);
      expect(performance.averagePct, 80);
      expect(performance.averageTwsMps, closeTo(mps(10), 1e-12));
      expect(performance.histogram, {160: 3});
      expect(performance.buckets, {
        5: const PolarBucket(seconds: 3, pctSecondsSum: 240),
      });
      expect(performance.bestFiveSecondsPct, isNull);
    });

    test('nothing for no samples', () {
      expect(run(const []), PolarPerformance.empty);
    });

    test('ten-second samples with their weight', () {
      // Given: hat regi minta 10 mp-enkent
      final samples = [
        for (var index = 0; index < 6; index++)
          sample(index * 10, durationSeconds: 10),
      ];

      // When
      final performance = run(samples);

      // Then
      expect(performance.measuredSeconds, 60);
      expect(performance.hasEnoughData, isTrue);
      expect(performance.histogram, {160: 60});
      expect(performance.bestFiveSecondsPct, isNull);
    });
  });

  group('SummarizePolarPerformance skips', () {
    test('samples that are no polar sample', () {
      // Given: hianyzo meresek, no-go zona, NaN es negativ sebesseg
      final samples = [
        sample(0),
        sample(1, twaDeg: null),
        sample(2, stwKnots: null),
        sample(3, twsKnots: null),
        sample(4, twaDeg: 20),
        sample(5, twaDeg: double.nan),
        sample(6, stwKnots: -1),
        sample(7),
        sample(8, twaDeg: -60),
      ];

      // When
      final performance = run(samples);

      // Then: a 0., a 7. es a bal halzos 8. minta szamit
      expect(performance.measuredSeconds, 3);
    });

    test('a TWS spike against its rolling median', () {
      // Given: egy 68 kn-os tuske 10 kn-os szelben (a Kekszalag-eset)
      final samples = [
        for (final (index, knots) in [10, 10, 10, 68, 10, 10, 10].indexed)
          sample(index, twsKnots: knots.toDouble()),
      ];

      // When
      final performance = run(samples);

      // Then
      expect(performance.measuredSeconds, 6);
    });

    test('no three-sample gust', () {
      // Given: harom mintas, 25 kn-os valodi lokes
      final samples = [
        for (final (index, knots) in [10, 10, 25, 25, 25, 10, 10].indexed)
          sample(index, twsKnots: knots.toDouble()),
      ];

      // When
      final performance = run(samples);

      // Then
      expect(performance.measuredSeconds, 7);
      expect(performance.buckets.keys, unorderedEquals([5, 12]));
    });
  });

  group('SummarizePolarPerformance percentages', () {
    test('use the STW correction from its start', () {
      // Given: a 2. masodperctol 1,1-es szorzo
      final corrections = [
        StwCorrection(from: start.add(const Duration(seconds: 2)), factor: 1.1),
      ];

      // When
      final performance = run([
        for (var second = 0; second < 4; second++) sample(second),
      ], corrections: corrections);

      // Then: 80% elotte, 88% utana
      expect(performance.histogram, {160: 2, 176: 2});
      expect(performance.pctSecondsSum, closeTo(336, 1e-9));
    });

    test('above 300 percent land in the overflow bin', () {
      // When: 16 kn STW 5 kn-os celra: 320%
      final performance = run([sample(0, stwKnots: 16)]);

      // Then
      expect(performance.histogram, {PolarPerformanceRules.overflowBin: 1});
      expect(performance.percentilePct(0.5), 300);
    });
  });

  group('SummarizePolarPerformance best five seconds', () {
    test('is the best average of five consecutive seconds', () {
      // Given: 80, 80, majd ot 100%-os masodperc
      final samples = [
        for (final (index, knots) in [4, 4, 5, 5, 5, 5, 5].indexed)
          sample(index, stwKnots: knots.toDouble()),
      ];

      // Then
      expect(run(samples).bestFiveSecondsPct, 100);
    });

    test('is broken by a missing second', () {
      // Given: a 3. masodperc hianyzik
      final samples = [
        for (final second in [0, 1, 2, 4, 5, 6]) sample(second, stwKnots: 5),
      ];

      // Then
      expect(run(samples).bestFiveSecondsPct, isNull);
    });

    test('is broken by a rejected sample', () {
      // Given: a 3. masodperc a no-go zonaban
      final samples = [
        for (var second = 0; second < 7; second++)
          sample(second, stwKnots: 5, twaDeg: second == 3 ? 10 : 60),
      ];

      // When
      final performance = run(samples);

      // Then
      expect(performance.measuredSeconds, 6);
      expect(performance.bestFiveSecondsPct, isNull);
    });
  });
}
