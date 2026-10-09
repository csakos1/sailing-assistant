import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:foretack_web/season_stats/wind_band.dart';

WindBand bandOfKnots(double knots) =>
    WindBand.ofMetersPerSecond(knotsToMetersPerSecond(knots));

void main() {
  group('WindBand.ofMetersPerSecond', () {
    test('puts calm races below 4 kn', () {
      expect(bandOfKnots(0), WindBand.below4);
      expect(bandOfKnots(3.94), WindBand.below4);
    });

    test('rounds to the shown tenth before the boundary check', () {
      // 3,96 kn a tablazatban 4,0-kent latszik (P3)
      expect(bandOfKnots(3.96), WindBand.from4To8);
      expect(bandOfKnots(4), WindBand.from4To8);
    });

    test('closes each band at its lower boundary', () {
      expect(bandOfKnots(7.9), WindBand.from4To8);
      expect(bandOfKnots(8), WindBand.from8To12);
      expect(bandOfKnots(12), WindBand.from12To16);
      expect(bandOfKnots(15.9), WindBand.from12To16);
    });

    test('puts strong wind into the top band', () {
      expect(bandOfKnots(16), WindBand.from16);
      expect(bandOfKnots(35), WindBand.from16);
    });
  });
}
