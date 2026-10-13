import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';

void main() {
  PolarBuildRejection? rejectionOf({
    double twaDeg = 60,
    double twsKnots = 10,
    double stwKnots = 5,
  }) => PolarBuildRejection.of(
    LabSample(
      raceId: 'r1',
      season: 2026,
      source: PolarSampleSource.telemetry,
      absTwaDeg: twaDeg,
      twsKnots: twsKnots,
      stwKnots: stwKnots,
      seconds: 1,
    ),
  );

  group('PolarBuildRejection.of', () {
    test('accepts an ordinary sample', () {
      expect(rejectionOf(), isNull);
    });

    test('drops the water speed at and beyond the limits', () {
      expect(rejectionOf(stwKnots: 0.3), PolarBuildRejection.waterSpeed);
      expect(rejectionOf(stwKnots: 0.31), isNull);
      expect(rejectionOf(stwKnots: 11.99), isNull);
      expect(rejectionOf(stwKnots: 12), PolarBuildRejection.waterSpeed);
    });

    test('drops calm downwind samples only below 2 knots', () {
      expect(
        rejectionOf(twaDeg: 177.5, twsKnots: 1.99),
        PolarBuildRejection.calm,
      );
      expect(rejectionOf(twaDeg: 177.4, twsKnots: 1.5), isNull);
      expect(rejectionOf(twaDeg: 180, twsKnots: 2), isNull);
    });

    test('drops the wind below one knot', () {
      expect(rejectionOf(twsKnots: 0.99), PolarBuildRejection.lightAir);
      expect(rejectionOf(twsKnots: 1), isNull);
    });

    test('drops the no-go rows', () {
      expect(rejectionOf(twaDeg: 22.4), PolarBuildRejection.noGo);
      expect(rejectionOf(twaDeg: 22.5), isNull);
    });

    test('names the first reason in order', () {
      expect(
        rejectionOf(twaDeg: 179, twsKnots: 0.5, stwKnots: 0.1),
        PolarBuildRejection.waterSpeed,
      );
      expect(rejectionOf(twaDeg: 179, twsKnots: 0.5), PolarBuildRejection.calm);
    });
  });
}
