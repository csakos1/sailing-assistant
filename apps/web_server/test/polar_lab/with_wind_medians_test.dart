import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/with_wind_medians.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(
    int second, {
    double? twaDeg = 60,
    double? twsKnots = 10,
    double stwKnots = 5,
  }) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: twsKnots == null ? null : mps(twsKnots),
    stwMps: mps(stwKnots),
  );

  List<double?> anglesOf(List<PolarSample> samples) => [
    for (final smoothed in samples) smoothed.twaDeg,
  ];

  group('withWindMedians', () {
    test('replaces the wind with the median of its window', () {
      // ARRANGE: egy 90 fokos, 30 kn-os kiugras a 60 fokos, 10 kn-os szelben
      final samples = [
        sample(0),
        sample(1),
        sample(2, twaDeg: 90, twsKnots: 30),
        sample(3),
        sample(4),
      ];

      // ACT
      final smoothed = withWindMedians(samples, halfWindowSeconds: 1);

      // ASSERT
      expect(anglesOf(smoothed), [60, 60, 60, 60, 60]);
      expect(smoothed[2].twsMps, closeTo(mps(10), 1e-9));
    });

    test('takes the median of the absolute angle across 180 degrees', () {
      final smoothed = withWindMedians(
        [
          sample(0, twaDeg: 170),
          sample(1, twaDeg: -175),
          sample(2, twaDeg: 178),
        ],
        halfWindowSeconds: 1,
      );

      // A ket szelen ket elem: az also median; kozepen a harom kozepe.
      expect(anglesOf(smoothed), [170, 175, 175]);
    });

    test('keeps a sample without wind without wind', () {
      final smoothed = withWindMedians(
        [sample(0), sample(1, twaDeg: null, twsKnots: null), sample(2)],
        halfWindowSeconds: 1,
      );

      expect(smoothed[1].twaDeg, isNull);
      expect(smoothed[1].twsMps, isNull);
      expect(smoothed[0].twaDeg, 60);
    });

    test('keeps an invalid own value for the later filter', () {
      final smoothed = withWindMedians(
        [sample(0), sample(1, twaDeg: double.nan, twsKnots: -1), sample(2)],
        halfWindowSeconds: 1,
      );

      expect(smoothed[1].twaDeg, isNaN);
      expect(smoothed[1].twsMps, closeTo(mps(-1), 1e-9));
    });

    test('rejects a negative half window', () {
      expect(
        () => withWindMedians([sample(0)], halfWindowSeconds: -1),
        throwsArgumentError,
      );
    });

    test('looks only inside the time window', () {
      // A 10 mp-es hezag miatt a ket minta nem latja egymast.
      final smoothed = withWindMedians(
        [sample(0, twaDeg: 40), sample(10, twaDeg: 80)],
        halfWindowSeconds: 2,
      );

      expect(anglesOf(smoothed), [40, 80]);
    });

    test('keeps the time, the water speed and the weight', () {
      final original = sample(0, stwKnots: 6);

      final smoothed = withWindMedians([original], halfWindowSeconds: 5).single;

      expect(smoothed.timestamp, original.timestamp);
      expect(smoothed.stwMps, original.stwMps);
      expect(smoothed.durationSeconds, original.durationSeconds);
    });
  });
}
