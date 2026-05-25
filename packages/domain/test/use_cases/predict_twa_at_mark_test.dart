import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/use_cases/predict_twa_at_mark.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:test/test.dart';

void main() {
  group('PredictTwaAtMark', () {
    const useCase = PredictTwaAtMark();

    // Közös valid trend fixtúra a happy-path tesztekhez. A confidence
    // irreleváns a 7.5-nek (nem szűr rá), high-ot adunk mindenhol.
    WindShiftTrend trendWith({
      required double shiftRate,
      required Bearing currentTwd,
    }) {
      return WindShiftTrend(
        shiftRateDegPerMinute: shiftRate,
        currentTwd: currentTwd,
        confidence: WindShiftConfidence.high,
        sampleCount: 12,
        windowDuration: const Duration(minutes: 10),
      );
    }

    group('null-szemantika', () {
      test('null trend → null', () {
        // ARRANGE & ACT
        final result = useCase(
          courseToMark: const Bearing.true_(90),
          trend: null,
          timeToMark: const Duration(seconds: 600),
        );

        // ASSERT
        expect(result, isNull);
      });

      test('null timeToMark → null', () {
        final result = useCase(
          courseToMark: const Bearing.true_(90),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(100)),
          timeToMark: null,
        );

        expect(result, isNull);
      });
    });

    group('happy path', () {
      test('zero timeToMark + courseToMark == currentTwd → TWA 0', () {
        // shiftDeg = 5 * 0 / 60 = 0 → predictedTwd 45; 45 - 45 = 0
        final result = useCase(
          courseToMark: const Bearing.true_(45),
          trend: trendWith(shiftRate: 5, currentTwd: const Bearing.true_(45)),
          timeToMark: Duration.zero,
        );

        expect(result, equals(const Angle(degrees: 0)));
      });

      test('pozitív shift (clockwise) → előre tolt TWA', () {
        // currentTwd 100 + (6°/min * 5 min = 30) = predictedTwd 130
        // TWA = 130 - 90 = 40
        final result = useCase(
          courseToMark: const Bearing.true_(90),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(100)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 40)));
      });

      test('negatív shift (counterclockwise) → port felé tolt TWA', () {
        // currentTwd 100 + (-6 * 5 = -30) = predictedTwd 70
        // TWA = 70 - 90 = -20
        final result = useCase(
          courseToMark: const Bearing.true_(90),
          trend: trendWith(shiftRate: -6, currentTwd: const Bearing.true_(100)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: -20)));
      });
    });

    group('wrap-around és signed shortest-path', () {
      test('predictedTwd átfut 360-on (350 + 30 → 20)', () {
        // currentTwd 350 + 30 = 380 % 360 = 20 = predictedTwd
        // TWA = 20 - 0 = 20
        final result = useCase(
          courseToMark: const Bearing.true_(0),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(350)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 20)));
      });

      test('200°-os nyers különbség → signed shortest-path -160', () {
        // currentTwd 170 + 30 = 200 = predictedTwd
        // nyersen 200 - 0 = 200, signed shortest-path → -160 (port)
        final result = useCase(
          courseToMark: const Bearing.true_(0),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(170)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: -160)));
      });
    });

    group('nagy shift × hosszú idő', () {
      test('100°-os előrejelzés → finite, helyes signed TWA', () {
        // currentTwd 50 + (10°/min * 10 min = 100) = predictedTwd 150
        // TWA = 150 - 20 = 130 (finite; NaN sosem egyenlő 130-cal)
        final result = useCase(
          courseToMark: const Bearing.true_(20),
          trend: trendWith(shiftRate: 10, currentTwd: const Bearing.true_(50)),
          timeToMark: const Duration(minutes: 10),
        );

        expect(result, equals(const Angle(degrees: 130)));
      });
    });
  });
}
