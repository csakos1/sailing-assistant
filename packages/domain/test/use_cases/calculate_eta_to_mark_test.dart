import 'package:domain/src/use_cases/calculate_eta_to_mark.dart';
import 'package:domain/src/value_objects/distance.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:test/test.dart';

void main() {
  group('CalculateEtaToMark', () {
    const useCase = CalculateEtaToMark();

    group('null-szemantika', () {
      test('null speedOverGround → null', () {
        // ARRANGE & ACT
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: null,
        );

        // ASSERT
        expect(result, isNull);
      });

      test('SOG a drift-küszöb alatt (0.05 m/s) → null', () {
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: const Speed(metersPerSecond: 0.05),
        );

        expect(result, isNull);
      });

      test('SOG pontosan a küszöbön (0.1 m/s) → null (strict >)', () {
        // A guard `> _minSpeedMetersPerSecond`, így a küszöb-érték még
        // álló helyzetnek számít.
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: const Speed(metersPerSecond: 0.1),
        );

        expect(result, isNull);
      });
    });

    group('happy path', () {
      test('1000 m / 5 m/s → 200 s', () {
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: const Speed(metersPerSecond: 5),
        );

        expect(result, equals(const Duration(seconds: 200)));
      });

      test('épp a küszöb felett (0.11 m/s) → véges ETA', () {
        // 100 / 0.11 = 909.09… → 909 s
        final result = useCase(
          distance: const Distance(meters: 100),
          speedOverGround: const Speed(metersPerSecond: 0.11),
        );

        expect(result, equals(const Duration(seconds: 909)));
      });

      test('distance 0 → Duration.zero', () {
        final result = useCase(
          distance: const Distance(meters: 0),
          speedOverGround: const Speed(metersPerSecond: 5),
        );

        expect(result, equals(Duration.zero));
      });

      test('nem egész hányados a legközelebbi másodpercre kerekül', () {
        // 1000 / 3 = 333.33… → round → 333 s
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: const Speed(metersPerSecond: 3),
        );

        expect(result, equals(const Duration(seconds: 333)));
      });
    });

    group('defenzív', () {
      test('NaN SOG (default ctor) → null', () {
        // A default ctor nem validál; ha NaN jutna a domain-be, a
        // pozitív feltétel `false`-ot ad, így null — nem propagálunk
        // NaN ETA-t.
        final result = useCase(
          distance: const Distance(meters: 1000),
          speedOverGround: const Speed(metersPerSecond: double.nan),
        );

        expect(result, isNull);
      });
    });
  });
}
