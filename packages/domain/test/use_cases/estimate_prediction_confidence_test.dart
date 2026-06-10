import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/use_cases/estimate_prediction_confidence.dart';
import 'package:test/test.dart';

void main() {
  group('EstimatePredictionConfidence', () {
    const useCase = EstimatePredictionConfidence();

    group('band-képlet', () {
      test('csak reziduum (slopeSE 0) → band = s', () {
        final r = useCase(
          residualStdErrorDeg: 4,
          slopeStdErrorDegPerMin: 0,
          horizon: const Duration(minutes: 10),
        );

        expect(r.bandDegrees, closeTo(4, 1e-9));
      });

      test('reziduum + slope·horizont → pitagoraszi összeg (3-4-5)', () {
        // s = 3; slopeSE 0.4 °/perc · 10 perc = 4 → band = sqrt(9+16) = 5.
        final r = useCase(
          residualStdErrorDeg: 3,
          slopeStdErrorDegPerMin: 0.4,
          horizon: const Duration(minutes: 10),
        );

        expect(r.bandDegrees, closeTo(5, 1e-9));
        expect(r.confidence, WindShiftConfidence.high);
      });

      test('horizon 0 → a slope-tag eltűnik, band = s', () {
        final r = useCase(
          residualStdErrorDeg: 12,
          slopeStdErrorDegPerMin: 100,
          horizon: Duration.zero,
        );

        expect(r.bandDegrees, closeTo(12, 1e-9));
        expect(r.confidence, WindShiftConfidence.medium);
      });
    });

    group('bucket-határok', () {
      test('band = 6 → high (≤ 6 inkluzív)', () {
        final r = useCase(
          residualStdErrorDeg: 6,
          slopeStdErrorDegPerMin: 0,
          horizon: const Duration(minutes: 5),
        );
        expect(r.confidence, WindShiftConfidence.high);
      });

      test('band kicsivel 6 fölött → medium', () {
        final r = useCase(
          residualStdErrorDeg: 6.5,
          slopeStdErrorDegPerMin: 0,
          horizon: const Duration(minutes: 5),
        );
        expect(r.confidence, WindShiftConfidence.medium);
      });

      test('band = 15 → medium (≤ 15 inkluzív)', () {
        final r = useCase(
          residualStdErrorDeg: 15,
          slopeStdErrorDegPerMin: 0,
          horizon: const Duration(minutes: 5),
        );
        expect(r.confidence, WindShiftConfidence.medium);
      });

      test('band kicsivel 15 fölött → low', () {
        final r = useCase(
          residualStdErrorDeg: 16,
          slopeStdErrorDegPerMin: 0,
          horizon: const Duration(minutes: 5),
        );
        expect(r.confidence, WindShiftConfidence.low);
      });
    });

    group('defenzív viselkedés', () {
      test('NaN reziduum → NaN band → low', () {
        final r = useCase(
          residualStdErrorDeg: double.nan,
          slopeStdErrorDegPerMin: 0.5,
          horizon: const Duration(minutes: 10),
        );

        expect(r.bandDegrees.isNaN, isTrue);
        expect(r.confidence, WindShiftConfidence.low);
      });

      test('NaN slopeSE → NaN band → low', () {
        final r = useCase(
          residualStdErrorDeg: 2,
          slopeStdErrorDegPerMin: double.nan,
          horizon: const Duration(minutes: 10),
        );

        expect(r.bandDegrees.isNaN, isTrue);
        expect(r.confidence, WindShiftConfidence.low);
      });
    });
  });
}
