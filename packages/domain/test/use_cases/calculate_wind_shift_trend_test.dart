import 'package:domain/src/entities/wind_observation.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/use_cases/calculate_wind_shift_trend.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:test/test.dart';

void main() {
  // Determinisztikus "most" — minden teszt ugyanazt a fix időpontot
  // használja a now paraméterhez. Nincs `DateTime.now()` a forrásban.
  final now = DateTime.utc(2026, 5, 17, 12);
  const window = Duration(minutes: 10);
  const useCase = CalculateWindShiftTrend();

  // Helper: n mintás history, 1/min ütem, az utolsó minta `now`-on.
  // A TWD lineárisan emelkedik (vagy süllyed, ha stepPerMin negatív),
  // `[0, 360)`-ra wrap-elve.
  List<WindObservation> linearHistory({
    required double twd0,
    required double stepPerMin,
    required int count,
  }) {
    return List<WindObservation>.generate(count, (i) {
      final twd = (twd0 + stepPerMin * i) % 360;
      return WindObservation(
        twd: Bearing.true_(twd),
        timestamp: now.subtract(Duration(minutes: count - 1 - i)),
      );
    });
  }

  group('CalculateWindShiftTrend', () {
    group('insufficient samples → null', () {
      test('empty history → null', () {
        final result = useCase(history: const [], window: window, now: now);
        expect(result, isNull);
      });

      test('history with 9 samples in window → null', () {
        final history = linearHistory(twd0: 100, stepPerMin: 1, count: 9);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNull);
      });
    });

    group('happy path — perfekt monotonikus trend', () {
      test('boundary: exactly 10 samples, +1°/min → high confidence', () {
        final history = linearHistory(twd0: 100, stepPerMin: 1, count: 10);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(result!.shiftRateDegPerMinute, closeTo(1, 1e-6));
        expect(result.confidence, equals(WindShiftConfidence.high));
        expect(result.sampleCount, equals(10));
        expect(result.windowDuration, equals(window));
      });

      test('20 samples, +2°/min → high confidence (only recent in window)', () {
        // 20 perces history, 10 perces window → a window filtering
        // után csak a recent 10 minta számít.
        final history = linearHistory(twd0: 100, stepPerMin: 2, count: 20);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(result!.shiftRateDegPerMinute, closeTo(2, 1e-6));
        expect(result.confidence, equals(WindShiftConfidence.high));
      });

      test('negative slope (counterclockwise) → negative shiftRate', () {
        final history = linearHistory(twd0: 200, stepPerMin: -1, count: 15);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(result!.shiftRateDegPerMinute, closeTo(-1, 1e-6));
        expect(result.confidence, equals(WindShiftConfidence.high));
      });
    });

    group('wrap-around handling', () {
      test('crossing 0° clockwise (355 → 5) → slope ~ +1, currentTwd ~ 5', () {
        // 355, 356, ..., 359, 0, 1, ..., 5 — 11 minta, +1°/min
        final history = linearHistory(twd0: 355, stepPerMin: 1, count: 11);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(result!.shiftRateDegPerMinute, closeTo(1, 1e-6));
        expect(result.currentTwd.degrees, closeTo(5, 1e-6));
        expect(
          result.currentTwd.reference,
          equals(BearingReference.trueNorth),
        );
      });
    });

    group('degenerált fit → null', () {
      test('konstans TWD (no shift) → r² NaN → null', () {
        final history = linearHistory(twd0: 180, stepPerMin: 0, count: 15);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNull);
      });
    });

    group('time-window filtering', () {
      test('samples both inside and outside window: only recent count', () {
        // Old: now - 20..now - 11, slope +5°/min — mind cutoff előtt.
        // Recent: now - 9..now, slope +1°/min — mind cutoff után.
        // Ha a use case helyesen szűr, csak a +1°/min trend látszik.
        final old = List<WindObservation>.generate(10, (i) {
          return WindObservation(
            twd: Bearing.true_((50 + i * 5) % 360),
            timestamp: now.subtract(Duration(minutes: 20 - i)),
          );
        });
        final recent = linearHistory(twd0: 100, stepPerMin: 1, count: 10);
        final history = [...old, ...recent];

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(result!.shiftRateDegPerMinute, closeTo(1, 1e-6));
        expect(result.sampleCount, equals(10));
      });

      test('only old samples (all outside window) → null', () {
        final history = List<WindObservation>.generate(15, (i) {
          return WindObservation(
            twd: Bearing.true_(100 + i.toDouble()),
            timestamp: now.subtract(Duration(minutes: 30 - i)),
          );
        });

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNull);
      });

      test('different `now` shifts the window deterministically', () {
        final history = linearHistory(twd0: 100, stepPerMin: 1, count: 20);

        final r1 = useCase(history: history, window: window, now: now);
        final r2 = useCase(
          history: history,
          window: window,
          now: now.add(const Duration(minutes: 100)),
        );

        expect(r1, isNotNull);
        expect(r2, isNull);
      });
    });

    group('return value invariants', () {
      test('currentTwd is trueNorth-referenced and in [0, 360)', () {
        final history = linearHistory(twd0: 350, stepPerMin: 1, count: 11);

        final result = useCase(history: history, window: window, now: now);

        expect(result, isNotNull);
        expect(
          result!.currentTwd.reference,
          equals(BearingReference.trueNorth),
        );
        expect(result.currentTwd.degrees, greaterThanOrEqualTo(0));
        expect(result.currentTwd.degrees, lessThan(360));
      });

      test('windowDuration and sampleCount pass through correctly', () {
        // 15 mintás history 1/min ütemmel: now - 14..now
        // 12 perces window → cutoff = now - 12 → recent: now - 11..now
        // = 12 minta (a now - 12 minta isAfter(cutoff) NEM > now - 12, ki).
        final history = linearHistory(twd0: 100, stepPerMin: 1, count: 15);
        const customWindow = Duration(minutes: 12);

        final result = useCase(
          history: history,
          window: customWindow,
          now: now,
        );

        expect(result, isNotNull);
        expect(result!.windowDuration, equals(customWindow));
        expect(result.sampleCount, equals(12));
      });
    });
  });
}
