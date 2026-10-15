import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/local_quadratic_smooth.dart';

void main() {
  List<double> positionsFrom(int count) => [
    for (var index = 0; index < count; index++) 25.0 + 5 * index,
  ];

  List<double?> smooth(
    List<double?> values, {
    List<double>? weights,
  }) => localQuadraticSmooth(
    positions: positionsFrom(values.length),
    values: values,
    weights: weights ?? List.filled(values.length, 100),
    bandwidth: 15,
  );

  Matcher closeToAll(List<double> expected) => pairwiseCompare(
    expected,
    (double want, double? got) => got != null && (got - want).abs() < 1e-9,
    'within 1e-9 of',
  );

  group('localQuadraticSmooth', () {
    test('returns a parabola unchanged', () {
      double parabola(double x) => 0.001 * x * x + 0.05 * x + 3;
      final positions = positionsFrom(8);

      final smoothed = smooth([for (final x in positions) parabola(x)]);

      expect(smoothed, closeToAll([for (final x in positions) parabola(x)]));
    });

    test('fills a hole inside the measured range', () {
      final smoothed = smooth([4, 4.5, null, 5.5, 6]);

      expect(smoothed, closeToAll([4, 4.5, 5, 5.5, 6]));
    });

    test('leaves the rows outside the measured range empty', () {
      final smoothed = smooth([null, 5, 5, 5, null]);

      expect(smoothed.first, isNull);
      expect(smoothed.last, isNull);
      expect(smoothed.sublist(1, 4), closeToAll([5, 5, 5]));
    });

    test('bridges a hole wider than the bandwidth linearly', () {
      // ARRANGE: 25-30 fok 4 kn, 60-65 fok 6 kn, kozte nincs meres
      final values = [4.0, 4.0, null, null, null, null, null, 6.0, 6.0];

      // ACT
      final smoothed = smooth(values);

      // ASSERT: a lyuk soraiban legfeljebb egy oldalon van mert pont, ezert
      // a 30 es a 60 fok kozti egyenes
      expect(
        smoothed,
        closeToAll([4, 4, 4 + 1 / 3, 4 + 2 / 3, 5, 5 + 1 / 3, 5 + 2 / 3, 6, 6]),
      );
    });

    test('does not extrapolate from one side into a hole', () {
      // ARRANGE: 25-30 fok mert, 35 fokon csak bal oldali szomszed van
      final values = [4.0, 4.5, null, null, null, 6.0];

      // ACT
      final smoothed = smooth(values);

      // ASSERT: a 40 fok ket oldalrol (30, 50) illesztett; a 35 es a 45
      // fok egy oldalu, azok a szomszedok egyenesen
      expect(smoothed, closeToAll([4, 4.5, 4.875, 5.25, 5.625, 6]));
    });

    test('damps a single outlier', () {
      final smoothed = smooth([5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5]);

      expect(smoothed[5], allOf(greaterThan(5.5), lessThan(6.5)));
      expect(smoothed.first, closeTo(5, 1e-9));
    });

    test('pulls toward the cell with more time', () {
      final values = <double?>[5, 5, 5, 8];

      final heavy = smooth(values, weights: [1, 1, 1, 1000]);
      final light = smooth(values, weights: [1000, 1000, 1000, 1]);

      // A `!` biztonsagos: a 35 fokos sor a mert tartomanyban van.
      expect(heavy[2]! - light[2]!, greaterThan(0.3));
    });

    test('gives nothing without a measured value', () {
      expect(smooth([null, null]), [null, null]);
    });

    test('rejects lists of different length and a bad bandwidth', () {
      expect(
        () => localQuadraticSmooth(
          positions: [25, 30],
          values: [5],
          weights: [1, 1],
          bandwidth: 15,
        ),
        throwsArgumentError,
      );
      expect(
        () => localQuadraticSmooth(
          positions: [25],
          values: [5],
          weights: [1],
          bandwidth: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
