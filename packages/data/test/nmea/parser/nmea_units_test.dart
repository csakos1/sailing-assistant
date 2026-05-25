import 'package:data/src/nmea/parser/nmea_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nmea_units', () {
    group('metersPerSecondFromKnots', () {
      test('1 csomó ≈ 0.5144 m/s', () {
        expect(metersPerSecondFromKnots(1), closeTo(0.5144, 0.0001));
      });

      test('0 csomó -> 0 m/s', () {
        expect(metersPerSecondFromKnots(0), equals(0));
      });

      test('a valós RMC SOG-ja (4.5 csomó) = 2.315 m/s', () {
        // A golden RMC sor SOG-mezője; az RMC dekóder tesztje is erre épít.
        expect(metersPerSecondFromKnots(4.5), closeTo(2.315, 0.001));
      });
    });

    group('metersPerSecondFromKmh', () {
      test('3.6 km/h = 1 m/s', () {
        expect(metersPerSecondFromKmh(3.6), closeTo(1, 1e-9));
      });
    });
  });
}
