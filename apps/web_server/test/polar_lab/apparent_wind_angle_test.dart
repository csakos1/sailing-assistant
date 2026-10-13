import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/apparent_wind_angle.dart';

void main() {
  double awa(double twa, double tws, double stw) => apparentWindAngleDegrees(
    absTwaDeg: twa,
    twsKnots: tws,
    stwKnots: stw,
  );

  group('apparentWindAngleDegrees', () {
    test('equals the true wind angle when the boat stands still', () {
      expect(awa(90, 10, 0), closeTo(90, 1e-9));
    });

    test('moves forward with the boat speed', () {
      // tan(AWA) = 10 sin 45 / (10 cos 45 + 6)
      expect(awa(45, 10, 6), closeTo(28.4121, 1e-4));
    });

    test('comes from ahead when the boat outruns the wind downwind', () {
      expect(awa(180, 10, 5), closeTo(180, 1e-9));
      expect(awa(180, 5, 10), closeTo(0, 1e-9));
      // 6.8 kn 150 fokon 3 kn szelben: a szel szinte szembol jon.
      expect(awa(150, 3, 6.8), closeTo(19.6455, 1e-4));
    });

    test('stays zero head to wind', () {
      expect(awa(0, 10, 5), closeTo(0, 1e-9));
    });
  });
}
