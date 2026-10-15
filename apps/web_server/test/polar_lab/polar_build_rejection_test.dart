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
      // Lassan, hogy a szamolt AWA hatszel maradjon.
      expect(rejectionOf(twaDeg: 177.4, twsKnots: 1.5, stwKnots: 1), isNull);
      expect(
        rejectionOf(twaDeg: 177.5, twsKnots: 2, stwKnots: 1.5),
        PolarBuildRejection.deadDownwind,
      );
    });

    test('drops the wind below one knot', () {
      expect(rejectionOf(twsKnots: 0.99), PolarBuildRejection.lightAir);
      expect(rejectionOf(twsKnots: 1, stwKnots: 1), isNull);
    });

    test('drops the no-go rows', () {
      expect(rejectionOf(twaDeg: 22.4), PolarBuildRejection.noGo);
      expect(rejectionOf(twaDeg: 22.5), isNull);
    });

    test('drops a downwind sample with apparent wind under 20 degrees', () {
      // 150 fok, 3 kn szel, 6.8 kn: a szamolt AWA 19.6 fok
      expect(
        rejectionOf(twaDeg: 150, twsKnots: 3, stwKnots: 6.8),
        PolarBuildRejection.apparentWind,
      );
      // 5 kn szelben 5.2 kn: 70.8 fok
      expect(rejectionOf(twaDeg: 150, twsKnots: 5, stwKnots: 5.2), isNull);
      // 175 fokon a szelnel gyorsabban: az AWA 9.8 fok
      expect(
        rejectionOf(twaDeg: 175, twsKnots: 3, stwKnots: 4.5),
        PolarBuildRejection.apparentWind,
      );
    });

    test('drops an upwind sample only under 10 degrees', () {
      // 40 fok, 2 kn szel, 3.4 kn: 14.6 fok, kreuzban megengedett
      expect(rejectionOf(twaDeg: 40, twsKnots: 2, stwKnots: 3.4), isNull);
      // 30 fok, 2 kn szel, 6 kn: 7.4 fok
      expect(
        rejectionOf(twaDeg: 30, twsKnots: 2, stwKnots: 6),
        PolarBuildRejection.apparentWind,
      );
    });

    test('drops the 180 degree row', () {
      expect(
        rejectionOf(twaDeg: 180, stwKnots: 7),
        PolarBuildRejection.deadDownwind,
      );
      expect(rejectionOf(twaDeg: 177.4, stwKnots: 7), isNull);
    });

    test('drops a deep downwind VMG above 1.3 times the wind', () {
      // 150 fok, 4 kn szel, 6.8 kn: AWA 30.9 fok, de VMG/TWS = 1.47
      expect(
        rejectionOf(twaDeg: 150, twsKnots: 4, stwKnots: 6.8),
        PolarBuildRejection.downwindVmg,
      );
      // 134 fokon meg nem mely hatszel (VMG/TWS = 1.39)
      expect(rejectionOf(twaDeg: 134, twsKnots: 3, stwKnots: 6), isNull);
    });

    test('takes the VMG ratio as a parameter', () {
      const sample = LabSample(
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        absTwaDeg: 150,
        twsKnots: 4,
        stwKnots: 6.8,
        seconds: 1,
      );

      expect(
        PolarBuildRejection.downwindVmgRatioOf(sample),
        closeTo(1.47, 1e-2),
      );
      expect(
        PolarBuildRejection.of(sample, maximumDownwindVmgRatio: 1.5),
        isNull,
      );
      expect(
        PolarBuildRejection.of(
          sample,
          maximumDownwindVmgRatio: double.infinity,
        ),
        isNull,
      );
    });

    test('gives no VMG ratio outside deep downwind', () {
      const sample = LabSample(
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        absTwaDeg: 60,
        twsKnots: 4,
        stwKnots: 6.8,
        seconds: 1,
      );

      expect(PolarBuildRejection.downwindVmgRatioOf(sample), 0);
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
