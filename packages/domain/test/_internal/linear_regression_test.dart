import 'package:domain/src/_internal/linear_regression.dart';
import 'package:test/test.dart';

void main() {
  group('linearRegression', () {
    group('happy path', () {
      test('perfect fit y = 2x + 1 → slope = 2, r² = 1', () {
        // Arrange
        final x = <double>[0, 1, 2, 3, 4];
        final y = <double>[1, 3, 5, 7, 9];

        // Act
        final (slope, rSquared) = linearRegression(x, y);

        // Assert
        expect(slope, closeTo(2, 1e-9));
        expect(rSquared, closeTo(1, 1e-9));
      });

      test('perfect anti-correlation y = -2x + 1 → slope = -2, r² = 1', () {
        final x = <double>[0, 1, 2, 3, 4];
        final y = <double>[1, -1, -3, -5, -7];

        final (slope, rSquared) = linearRegression(x, y);

        expect(slope, closeTo(-2, 1e-9));
        expect(rSquared, closeTo(1, 1e-9));
      });

      test('noisy data → slope ~ ground truth, r² ∈ (0.99, 1)', () {
        // y ≈ x mild noise-szal
        final x = <double>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
        final y = <double>[
          0.1,
          1.05,
          1.95,
          3.1,
          3.9,
          5.2,
          5.85,
          7.1,
          7.95,
          9.05,
        ];

        final (slope, rSquared) = linearRegression(x, y);

        expect(slope, closeTo(1, 0.05));
        expect(rSquared, greaterThan(0.99));
        expect(rSquared, lessThan(1));
      });

      test('large absolute x (epoch-skála) → numerically stable', () {
        // x ~ epoch-ms/60000 nagyságrendje (~29 millió perc óta epoch).
        // A naív (n·Σx² − (Σx)²) catastrophic cancellation-t okozna;
        // a centered formulák megőrzik a slope-pontosságot.
        final x = <double>[29000000, 29000001, 29000002, 29000003];
        final y = <double>[10, 20, 30, 40];

        final (slope, rSquared) = linearRegression(x, y);

        expect(slope, closeTo(10, 1e-6));
        expect(rSquared, closeTo(1, 1e-9));
      });
    });

    group('NaN-tuple edge cases', () {
      test('empty input → (NaN, NaN)', () {
        final (slope, rSquared) = linearRegression(<double>[], <double>[]);
        expect(slope.isNaN, isTrue);
        expect(rSquared.isNaN, isTrue);
      });

      test('single point → (NaN, NaN)', () {
        final (slope, rSquared) = linearRegression(<double>[5], <double>[10]);
        expect(slope.isNaN, isTrue);
        expect(rSquared.isNaN, isTrue);
      });

      test('constant x (vertical fit) → (NaN, NaN)', () {
        final x = <double>[3, 3, 3, 3];
        final y = <double>[1, 2, 3, 4];

        final (slope, rSquared) = linearRegression(x, y);
        expect(slope.isNaN, isTrue);
        expect(rSquared.isNaN, isTrue);
      });

      test('constant y (no variance) → (NaN, NaN)', () {
        final x = <double>[1, 2, 3, 4];
        final y = <double>[5, 5, 5, 5];

        final (slope, rSquared) = linearRegression(x, y);
        expect(slope.isNaN, isTrue);
        expect(rSquared.isNaN, isTrue);
      });
    });

    group('hard fail', () {
      test('length mismatch → ArgumentError', () {
        expect(
          () => linearRegression(<double>[1, 2], <double>[1, 2, 3]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
