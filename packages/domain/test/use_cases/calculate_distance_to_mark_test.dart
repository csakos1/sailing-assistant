import 'package:domain/src/use_cases/calculate_distance_to_mark.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:test/test.dart';

void main() {
  group('CalculateDistanceToMark', () {
    const useCase = CalculateDistanceToMark();

    group('alapesetek (Balaton-skála)', () {
      test('from == to → 0 m', () {
        const point = Coordinate(latitude: 46.85, longitude: 17.85);
        final result = useCase(point, point);
        expect(result.meters, equals(0));
      });

      test('0.1° latitude északra → ~11119 m', () {
        const from = Coordinate(latitude: 46.85, longitude: 17.85);
        const to = Coordinate(latitude: 46.95, longitude: 17.85);
        // 0.1° × π × R / 180 ≈ 11119.5 m. ±100 m tolerancia.
        expect(useCase(from, to).meters, closeTo(11119, 100));
      });

      test('0.1° longitude keletre 46.85°N-en → ~7600 m', () {
        const from = Coordinate(latitude: 46.85, longitude: 17.85);
        const to = Coordinate(latitude: 46.85, longitude: 17.95);
        // 0.1° × π × R × cos(46.85°) / 180 ≈ 7600 m.
        expect(useCase(from, to).meters, closeTo(7600, 100));
      });

      test('szimmetrikus: f(a,b) == f(b,a)', () {
        const a = Coordinate(latitude: 46.85, longitude: 17.85);
        const b = Coordinate(latitude: 46.95, longitude: 17.95);
        expect(useCase(a, b).meters, closeTo(useCase(b, a).meters, 0.001));
      });
    });

    group('finom felbontás', () {
      test('1e-5° latitude → ~1.11 m (GPS-jitter tartomány)', () {
        const from = Coordinate(latitude: 46.85, longitude: 17.85);
        const to = Coordinate(latitude: 46.85001, longitude: 17.85);
        // 1e-5° × 111195 m/° ≈ 1.11 m.
        expect(useCase(from, to).meters, closeTo(1.11, 0.2));
      });
    });

    group('robosztusság', () {
      test('antipodális (egyenlítő 0°/180°) → π·R, véges, nincs NaN', () {
        const from = Coordinate(latitude: 0, longitude: 0);
        const to = Coordinate(latitude: 0, longitude: 180);
        final result = useCase(from, to);
        expect(result.meters.isFinite, isTrue);
        // π × 6371000 ≈ 20 015 087 m.
        expect(result.meters, closeTo(20015087, 100));
      });

      test('antimeridian crossing (179°E → -179°E egyenlítőn) → ~222 km', () {
        const from = Coordinate(latitude: 0, longitude: 179);
        const to = Coordinate(latitude: 0, longitude: -179);
        // dLon = -358° → sin²(dLon/2) = sin²(1°) → rövidebb 2°-os ív.
        expect(useCase(from, to).meters, closeTo(222390, 100));
      });

      test('pólustól pólusig (90°N → -90°N) → π·R', () {
        const from = Coordinate(latitude: 90, longitude: 0);
        const to = Coordinate(latitude: -90, longitude: 0);
        expect(useCase(from, to).meters, closeTo(20015087, 100));
      });
    });

    group('result invariáns', () {
      const from = Coordinate(latitude: 46.85, longitude: 17.85);
      const to = Coordinate(latitude: 46.90, longitude: 17.92);

      test('eredmény non-negatív', () {
        expect(useCase(from, to).meters, greaterThanOrEqualTo(0));
      });

      test('eredmény véges', () {
        expect(useCase(from, to).meters.isFinite, isTrue);
      });
    });
  });
}
