import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/use_cases/predict_twa_at_mark.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:test/test.dart';

void main() {
  group('PredictTwaAtMark', () {
    const useCase = PredictTwaAtMark();

    // Közös trend fixtúra. A confidence MOST SZÁMÍT (ADR 0021: low → nincs
    // extrapoláció); a happy-path tesztekhez high-ot adunk, a kapuzás-
    // tesztek expliciten állítják. windowDuration 10 perc, így a 600 mp-nél
    // rövidebb timeToMark nem ütközik az ablak-korlátba.
    WindShiftTrend trendWith({
      required double shiftRate,
      required Bearing currentTwd,
      WindShiftConfidence confidence = WindShiftConfidence.high,
    }) {
      return WindShiftTrend(
        shiftRateDegPerMinute: shiftRate,
        currentTwd: currentTwd,
        confidence: confidence,
        sampleCount: 12,
        windowDuration: const Duration(minutes: 10),
      );
    }

    group('null-szemantika', () {
      test('null trend → null', () {
        // ARRANGE & ACT
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: null,
          timeToMark: const Duration(seconds: 600),
        );

        // ASSERT
        expect(result, isNull);
      });

      test('null timeToMark → null', () {
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(100)),
          timeToMark: null,
        );

        expect(result, isNull);
      });
    });

    group('happy path', () {
      test('zero timeToMark + nextLegBearing == currentTwd → TWA 0', () {
        // shiftDeg = 5 * 0 / 60 = 0 → predictedTwd 45; 45 - 45 = 0
        final result = useCase(
          nextLegBearing: const Bearing.true_(45),
          trend: trendWith(shiftRate: 5, currentTwd: const Bearing.true_(45)),
          timeToMark: Duration.zero,
        );

        expect(result, equals(const Angle(degrees: 0)));
      });

      test('pozitív shift (clockwise) → előre tolt TWA', () {
        // currentTwd 100 + (6°/min * 5 min = 30) = predictedTwd 130
        // TWA = 130 - 90 = 40
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(100)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 40)));
      });

      test('negatív shift (counterclockwise) → port felé tolt TWA', () {
        // currentTwd 100 + (-6 * 5 = -30) = predictedTwd 70
        // TWA = 70 - 90 = -20
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
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
          nextLegBearing: const Bearing.true_(0),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(350)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 20)));
      });

      test('200°-os nyers különbség → signed shortest-path -160', () {
        // currentTwd 170 + 30 = 200 = predictedTwd
        // nyersen 200 - 0 = 200, signed shortest-path → -160 (port)
        final result = useCase(
          nextLegBearing: const Bearing.true_(0),
          trend: trendWith(shiftRate: 6, currentTwd: const Bearing.true_(170)),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: -160)));
      });
    });

    group('konfidencia-kapuzás és cap (ADR 0021)', () {
      test('low confidence → nincs extrapoláció (slope 0)', () {
        // A 6°/min slope-ot ELDOBJUK; a predikció a jelenlegi TWD.
        // predictedTwd 100; TWA = 100 - 90 = 10 (nincs eltolás).
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: trendWith(
            shiftRate: 6,
            currentTwd: const Bearing.true_(100),
            confidence: WindShiftConfidence.low,
          ),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 10)));
      });

      test('medium confidence → extrapolál (csak low szűr)', () {
        // medium → a slope érvényesül: 6 * 5 = 30 → predictedTwd 130
        // TWA = 130 - 90 = 40
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: trendWith(
            shiftRate: 6,
            currentTwd: const Bearing.true_(100),
            confidence: WindShiftConfidence.medium,
          ),
          timeToMark: const Duration(minutes: 5),
        );

        expect(result, equals(const Angle(degrees: 40)));
      });

      test('a nagy eltolás ±30°-ra vágódik (cap)', () {
        // 10°/min * 8 min = 80° → cap 30 (a timeToMark < ablak, nem az
        // ablak limitál). predictedTwd 50 + 30 = 80; TWA = 80 - 20 = 60.
        final result = useCase(
          nextLegBearing: const Bearing.true_(20),
          trend: trendWith(shiftRate: 10, currentTwd: const Bearing.true_(50)),
          timeToMark: const Duration(minutes: 8),
        );

        expect(result, equals(const Angle(degrees: 60)));
      });

      test('az extrapoláció a regressziós ablakra korlátozódik', () {
        // timeToMark 30 min, de az ablak 10 min → effectiveEta 10 min.
        // 2°/min * 10 min = 20° (< 30, nem vágódik) → predictedTwd 120;
        // TWA = 120 - 90 = 30. Ablak NÉLKÜL 2 * 30 = 60 → cap 30 → 40 lenne.
        final result = useCase(
          nextLegBearing: const Bearing.true_(90),
          trend: trendWith(shiftRate: 2, currentTwd: const Bearing.true_(100)),
          timeToMark: const Duration(minutes: 30),
        );

        expect(result, equals(const Angle(degrees: 30)));
      });
    });
  });
}
