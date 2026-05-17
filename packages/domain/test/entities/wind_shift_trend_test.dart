import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:test/test.dart';

void main() {
  group('WindShiftTrend', () {
    // Az invariáns-tesztek mindegyikében újrahasznosítjuk a TWD-t;
    // const lokális declaration, mert a `Bearing.true_` const ctor.
    const validTwd = Bearing.true_(180);

    WindShiftTrend buildValid() => WindShiftTrend(
      shiftRateDegPerMinute: 1.5,
      currentTwd: validTwd,
      confidence: WindShiftConfidence.high,
      sampleCount: 30,
      windowDuration: const Duration(minutes: 10),
    );

    group('construction', () {
      test('valid parameters → all fields readable', () {
        // Arrange / Act
        final trend = buildValid();

        // Assert
        expect(trend.shiftRateDegPerMinute, equals(1.5));
        expect(trend.currentTwd, equals(validTwd));
        expect(trend.confidence, equals(WindShiftConfidence.high));
        expect(trend.sampleCount, equals(30));
        expect(trend.windowDuration, equals(const Duration(minutes: 10)));
      });

      test('zero shift rate is allowed (stable wind)', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: 0,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.low,
            sampleCount: 10,
            windowDuration: const Duration(minutes: 10),
          ),
          returnsNormally,
        );
      });

      test('negative shift rate is allowed (counterclockwise)', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: -2.5,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.medium,
            sampleCount: 15,
            windowDuration: const Duration(minutes: 5),
          ),
          returnsNormally,
        );
      });
    });

    group('invariants', () {
      test('magnetic-referenced currentTwd → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: 1,
            currentTwd: const Bearing.magnetic_(180),
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: const Duration(minutes: 10),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative sampleCount → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: 1,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: -1,
            windowDuration: const Duration(minutes: 10),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('zero windowDuration → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: 1,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: Duration.zero,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative windowDuration → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: 1,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: const Duration(minutes: -1),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('NaN shift rate → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: double.nan,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: const Duration(minutes: 10),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('positive infinity shift rate → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: double.infinity,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: const Duration(minutes: 10),
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative infinity shift rate → AssertionError', () {
        expect(
          () => WindShiftTrend(
            shiftRateDegPerMinute: double.negativeInfinity,
            currentTwd: validTwd,
            confidence: WindShiftConfidence.high,
            sampleCount: 30,
            windowDuration: const Duration(minutes: 10),
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality', () {
      test('two trends with identical fields are equal', () {
        final a = buildValid();
        final b = buildValid();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different shiftRate → not equal', () {
        final a = buildValid();
        final b = a.copyWith(shiftRateDegPerMinute: 2.5);

        expect(a, isNot(equals(b)));
      });

      test('different confidence → not equal', () {
        final a = buildValid();
        final b = a.copyWith(confidence: WindShiftConfidence.low);

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('null parameters preserve all fields (no-op)', () {
        final a = buildValid();
        final b = a.copyWith();

        expect(b, equals(a));
      });

      test('single-field override leaves others intact', () {
        final a = buildValid();
        final b = a.copyWith(sampleCount: 99);

        expect(b.sampleCount, equals(99));
        expect(b.shiftRateDegPerMinute, equals(a.shiftRateDegPerMinute));
        expect(b.currentTwd, equals(a.currentTwd));
        expect(b.confidence, equals(a.confidence));
        expect(b.windowDuration, equals(a.windowDuration));
      });

      test('windowDuration override', () {
        final a = buildValid();
        final b = a.copyWith(windowDuration: const Duration(minutes: 20));

        expect(b.windowDuration, equals(const Duration(minutes: 20)));
      });
    });
  });
}
