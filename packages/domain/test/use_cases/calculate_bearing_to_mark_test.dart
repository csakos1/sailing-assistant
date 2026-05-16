import 'package:domain/src/use_cases/calculate_bearing_to_mark.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:test/test.dart';

void main() {
  group('CalculateBearingToMark', () {
    const useCase = CalculateBearingToMark();

    group('cardinal directions (Balaton-skála)', () {
      const center = Coordinate(latitude: 46.85, longitude: 17.85);

      test('észak: ugyanazon longitudon felfelé → ~0°', () {
        const to = Coordinate(latitude: 46.95, longitude: 17.85);
        expect(useCase(center, to).degrees, closeTo(0, 0.5));
      });

      test('kelet: ugyanazon latitudon jobbra → ~90°', () {
        const to = Coordinate(latitude: 46.85, longitude: 17.95);
        expect(useCase(center, to).degrees, closeTo(90, 0.5));
      });

      test('dél: ugyanazon longitudon lefelé → ~180°', () {
        const to = Coordinate(latitude: 46.75, longitude: 17.85);
        expect(useCase(center, to).degrees, closeTo(180, 0.5));
      });

      test('nyugat: ugyanazon latitudon balra → ~270°', () {
        const to = Coordinate(latitude: 46.85, longitude: 17.75);
        expect(useCase(center, to).degrees, closeTo(270, 0.5));
      });
    });

    group('antimeridian crossing (180° hosszúság)', () {
      test('kelet felé 179°E → -179°E: ~90° (a rövidebb +2° út)', () {
        const from = Coordinate(latitude: 0, longitude: 179);
        const to = Coordinate(latitude: 0, longitude: -179);
        expect(useCase(from, to).degrees, closeTo(90, 0.5));
      });

      test('nyugat felé -179°E → 179°E: ~270°', () {
        const from = Coordinate(latitude: 0, longitude: -179);
        const to = Coordinate(latitude: 0, longitude: 179);
        expect(useCase(from, to).degrees, closeTo(270, 0.5));
      });
    });

    group('edge case-ek', () {
      test('from == to → 0.0 (atan2(0,0) IEEE 754 konvenció)', () {
        const p = Coordinate(latitude: 46.85, longitude: 17.85);
        expect(useCase(p, p).degrees, equals(0.0));
      });

      test('magas latitudon véges és tartományon belüli marad', () {
        const from = Coordinate(latitude: 89, longitude: 0);
        const to = Coordinate(latitude: 89, longitude: 90);
        final result = useCase(from, to).degrees;
        expect(result.isFinite, isTrue);
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThan(360));
      });
    });

    group('result invariáns', () {
      const center = Coordinate(latitude: 46.85, longitude: 17.85);

      test('eredmény mindig BearingReference.trueNorth', () {
        const to = Coordinate(latitude: 46.95, longitude: 17.95);
        expect(
          useCase(center, to).reference,
          equals(BearingReference.trueNorth),
        );
      });

      test('eredmény degrees mindig [0, 360) tartományban', () {
        const targets = [
          Coordinate(latitude: 46.95, longitude: 17.85), // N
          Coordinate(latitude: 46.85, longitude: 17.95), // E
          Coordinate(latitude: 46.75, longitude: 17.85), // S
          Coordinate(latitude: 46.85, longitude: 17.75), // W
          Coordinate(latitude: 46.95, longitude: 17.95), // NE
          Coordinate(latitude: 46.75, longitude: 17.75), // SW
          Coordinate(latitude: 46.95, longitude: 17.75), // NW
          Coordinate(latitude: 46.75, longitude: 17.95), // SE
        ];
        for (final target in targets) {
          final deg = useCase(center, target).degrees;
          expect(deg, greaterThanOrEqualTo(0));
          expect(deg, lessThan(360));
        }
      });
    });
  });
}
