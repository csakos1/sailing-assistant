import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ComputeVmgSteerCorrection', () {
    const useCase = ComputeVmgSteerCorrection();

    group('érvényes halz/oldal', () {
      test('starboard, a célnál élesebb TWA → balra (ess le)', () {
        // Arrange: stbd +40, optimum 42 → 2°-ot le kell esni (balra).
        final correction = useCase(
          currentTwa: const Angle(degrees: 40),
          optimumTwaMagnitude: 42,
        );

        // Assert: 40 - 42 = -2 (negatív = balra/port).
        expect(correction?.degrees, closeTo(-2, 1e-9));
      });

      test('starboard, a célnál tágabb TWA → jobbra (állj fel)', () {
        // Arrange: stbd +50, optimum 42 → 8°-ot fel kell állni (jobbra).
        final correction = useCase(
          currentTwa: const Angle(degrees: 50),
          optimumTwaMagnitude: 42,
        );

        // Assert: 50 - 42 = +8 (pozitív = jobbra/starboard).
        expect(correction?.degrees, closeTo(8, 1e-9));
      });

      test('port, a célnál élesebb TWA → jobbra (ess le)', () {
        // Arrange: port -40, optimum 42 → 2°-ot le kell esni; port halzon
        // a leesés jobbra fordulás.
        final correction = useCase(
          currentTwa: const Angle(degrees: -40),
          optimumTwaMagnitude: 42,
        );

        // Assert: -40 - (-42) = +2.
        expect(correction?.degrees, closeTo(2, 1e-9));
      });

      test('port, a célnál tágabb TWA → balra (állj fel)', () {
        // Arrange: port -50, optimum 42 → 8°-ot fel kell állni (balra).
        final correction = useCase(
          currentTwa: const Angle(degrees: -50),
          optimumTwaMagnitude: 42,
        );

        // Assert: -50 - (-42) = -8.
        expect(correction?.degrees, closeTo(-8, 1e-9));
      });
    });

    group('null-ágak', () {
      test('no-go (|TWA| < küszöb) → null', () {
        // Arrange: a no-go küszöb (25°) alatt a halz kétértelmű.
        final belowThreshold = useCase(
          currentTwa: const Angle(degrees: 10),
          optimumTwaMagnitude: 42,
        );

        // Assert: nincs eldönthető optimum-oldal.
        expect(belowThreshold, isNull);
      });

      test('a no-go küszöbön (== küszöb) már számol', () {
        // Arrange: pontosan a küszöbön a feltétel (< küszöb) hamis.
        final atThreshold = useCase(
          currentTwa: const Angle(degrees: Polar.noGoThresholdDegrees),
          optimumTwaMagnitude: 42,
        );

        // Assert: 25 - 42 = -17, tehát NEM null.
        expect(atThreshold?.degrees, closeTo(-17, 1e-9));
      });

      test('nem-véges currentTwa → null', () {
        // Arrange: a default Angle ctor nem validál, így bejöhet ±∞.
        final infinite = useCase(
          currentTwa: const Angle(degrees: double.infinity),
          optimumTwaMagnitude: 42,
        );

        // Assert: a védőháló null-t ad.
        expect(infinite, isNull);
      });

      test('nem-véges optimum → null', () {
        // Arrange: NaN optimum-magnitúdó (hibás upstream szélsőérték).
        final nan = useCase(
          currentTwa: const Angle(degrees: 40),
          optimumTwaMagnitude: double.nan,
        );

        // Assert: a védőháló null-t ad.
        expect(nan, isNull);
      });
    });
  });
}
