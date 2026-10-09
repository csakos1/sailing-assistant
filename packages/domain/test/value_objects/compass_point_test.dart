import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CompassPoint.fromDegrees', () {
    test('maps every sector centre to its own point', () {
      for (final point in CompassPoint.values) {
        expect(CompassPoint.fromDegrees(point.centerDegrees), point);
      }
    });

    test('keeps values just below a boundary in the previous sector', () {
      expect(CompassPoint.fromDegrees(11.24), CompassPoint.north);
      expect(CompassPoint.fromDegrees(348.74), CompassPoint.northNorthWest);
    });

    test('puts the boundary itself into the next clockwise sector', () {
      expect(CompassPoint.fromDegrees(11.25), CompassPoint.northNorthEast);
      expect(CompassPoint.fromDegrees(348.75), CompassPoint.north);
    });

    test('wraps values around north', () {
      expect(CompassPoint.fromDegrees(359.9), CompassPoint.north);
      expect(CompassPoint.fromDegrees(360), CompassPoint.north);
    });

    test('normalises negative and over-full-circle values', () {
      expect(CompassPoint.fromDegrees(-90), CompassPoint.west);
      expect(CompassPoint.fromDegrees(450), CompassPoint.east);
    });
  });

  test('has 16 points in clockwise order from north', () {
    expect(CompassPoint.values, hasLength(16));
    expect(CompassPoint.east.centerDegrees, 90);
    expect(CompassPoint.southSouthWest.centerDegrees, 202.5);
  });
}
