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
        final reg = linearRegression(x, y);

        // Assert
        expect(reg.slope, closeTo(2, 1e-9));
        expect(reg.rSquared, closeTo(1, 1e-9));
        // Perfekt illesztés → nincs reziduum, a meredekség hibája is 0.
        expect(reg.residualStdError, closeTo(0, 1e-9));
        expect(reg.slopeStdError, closeTo(0, 1e-9));
        expect(reg.meanX, closeTo(2, 1e-9));
      });

      test('perfect anti-correlation y = -2x + 1 → slope = -2, r² = 1', () {
        final x = <double>[0, 1, 2, 3, 4];
        final y = <double>[1, -1, -3, -5, -7];

        final reg = linearRegression(x, y);

        expect(reg.slope, closeTo(-2, 1e-9));
        expect(reg.rSquared, closeTo(1, 1e-9));
        expect(reg.residualStdError, closeTo(0, 1e-9));
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

        final reg = linearRegression(x, y);

        expect(reg.slope, closeTo(1, 0.05));
        expect(reg.rSquared, greaterThan(0.99));
        expect(reg.rSquared, lessThan(1));
        // Zaj jelen → pozitív reziduál-szórás és meredekség-hiba.
        expect(reg.residualStdError, greaterThan(0));
        expect(reg.slopeStdError, greaterThan(0));
        expect(reg.meanX, closeTo(4.5, 1e-9));
      });

      test('large absolute x (epoch-skála) → numerically stable', () {
        // x ~ epoch-ms/60000 nagyságrendje (~29 millió perc óta epoch).
        // A naív (n·Σx² − (Σx)²) catastrophic cancellation-t okozna;
        // a centered formulák megőrzik a slope-pontosságot.
        final x = <double>[29000000, 29000001, 29000002, 29000003];
        final y = <double>[10, 20, 30, 40];

        final reg = linearRegression(x, y);

        expect(reg.slope, closeTo(10, 1e-6));
        expect(reg.rSquared, closeTo(1, 1e-9));
        expect(reg.meanX, closeTo(29000001.5, 1e-3));
      });
    });

    group('regresszió-statisztikák (ADR 0023)', () {
      test('ismert reziduum → s a négyzetes hibából, n−2 dof', () {
        // x=[0,1,2,3], y=[1,0,1,4]. A reziduumok (+1,−1,−1,+1) a centered
        // x-re ortogonálisak → az OLS slope pontosan 1 (a true slope).
        // SSres = Σr² = 4; s = sqrt(SSres/(n−2)) = sqrt(4/2) = sqrt(2).
        // Sxx = Σ(x−1.5)² = 5; slopeSE = s/sqrt(Sxx) = sqrt(2/5).
        final x = <double>[0, 1, 2, 3];
        final y = <double>[1, 0, 1, 4];

        final reg = linearRegression(x, y);

        expect(reg.slope, closeTo(1, 1e-9));
        expect(reg.residualStdError, closeTo(1.4142136, 1e-6));
        expect(reg.slopeStdError, closeTo(0.6324555, 1e-6));
        expect(reg.meanX, closeTo(1.5, 1e-9));
      });
    });

    group('NaN-record edge cases', () {
      test('empty input → minden mező NaN', () {
        final reg = linearRegression(<double>[], <double>[]);
        expect(reg.slope.isNaN, isTrue);
        expect(reg.rSquared.isNaN, isTrue);
        expect(reg.residualStdError.isNaN, isTrue);
        expect(reg.slopeStdError.isNaN, isTrue);
        expect(reg.meanX.isNaN, isTrue);
      });

      test('single point → minden mező NaN', () {
        final reg = linearRegression(<double>[5], <double>[10]);
        expect(reg.slope.isNaN, isTrue);
        expect(reg.rSquared.isNaN, isTrue);
        expect(reg.residualStdError.isNaN, isTrue);
        expect(reg.slopeStdError.isNaN, isTrue);
        expect(reg.meanX.isNaN, isTrue);
      });

      test('constant x (vertical fit) → minden mező NaN', () {
        final x = <double>[3, 3, 3, 3];
        final y = <double>[1, 2, 3, 4];

        final reg = linearRegression(x, y);
        expect(reg.slope.isNaN, isTrue);
        expect(reg.rSquared.isNaN, isTrue);
        expect(reg.residualStdError.isNaN, isTrue);
        expect(reg.slopeStdError.isNaN, isTrue);
      });

      test('constant y (no variance) → minden mező NaN', () {
        final x = <double>[1, 2, 3, 4];
        final y = <double>[5, 5, 5, 5];

        final reg = linearRegression(x, y);
        expect(reg.slope.isNaN, isTrue);
        expect(reg.rSquared.isNaN, isTrue);
        expect(reg.residualStdError.isNaN, isTrue);
        expect(reg.slopeStdError.isNaN, isTrue);
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
