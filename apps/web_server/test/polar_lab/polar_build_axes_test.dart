import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

void main() {
  LabSample labSample({
    double twaDeg = 60,
    double twsKnots = 23,
    int seconds = 1,
  }) => LabSample(
    raceId: 'r1',
    season: 2026,
    source: PolarSampleSource.telemetry,
    absTwaDeg: twaDeg,
    twsKnots: twsKnots,
    stwKnots: 8,
    seconds: seconds,
  );

  final baseAxes = PolarBuildAxes(
    twsColumnsKnots: PolarBuildAxes.baseTwsColumnsKnots,
  );

  group('PolarBuildAxes.forSamples', () {
    test('keeps the base axis without enough strong wind', () {
      final axes = PolarBuildAxes.forSamples([labSample(seconds: 1799)]);

      expect(axes.twsColumnsKnots, PolarBuildAxes.baseTwsColumnsKnots);
      expect(axes.hasStrongWindColumn, isFalse);
    });

    test('adds the 25 knot column with thirty minutes above 22.5', () {
      final axes = PolarBuildAxes.forSamples([
        labSample(seconds: 1700),
        labSample(twsKnots: 22.5, seconds: 100),
      ]);

      expect(axes.twsColumnsKnots.last, 25);
      expect(axes.hasStrongWindColumn, isTrue);
    });

    test('counts neither the no-go rows nor the wind below 22.5', () {
      final seconds = PolarBuildAxes.strongWindSecondsOf([
        labSample(twaDeg: 22.4, seconds: 5000),
        labSample(twsKnots: 22.4, seconds: 5000),
        labSample(twaDeg: 22.5, seconds: 7),
      ]);

      expect(seconds, 7);
    });
  });

  group('PolarBuildAxes.twsColumnOf', () {
    test('drops the wind below one knot and invalid wind', () {
      expect(baseAxes.twsColumnOf(0.99), isNull);
      expect(baseAxes.twsColumnOf(double.nan), isNull);
      expect(baseAxes.twsColumnOf(double.infinity), isNull);
    });

    test('puts light air into the 2 knot column', () {
      expect(baseAxes.twsColumnOf(1), 0);
      expect(baseAxes.twsColumnOf(2.49), 0);
    });

    test('takes the midpoint into the upper column', () {
      expect(baseAxes.twsColumnOf(2.5), 1);
      // 8 es 10 kozott a hatar 9.
      expect(baseAxes.twsColumnOf(8.99), 6);
      expect(baseAxes.twsColumnOf(9), 7);
    });

    test('puts the wind above the axis into the top column', () {
      expect(baseAxes.twsColumnOf(40), 11);

      final strongAxes = PolarBuildAxes(
        twsColumnsKnots: const [...PolarBuildAxes.baseTwsColumnsKnots, 25],
      );
      expect(strongAxes.twsColumnOf(22.49), 11);
      expect(strongAxes.twsColumnOf(22.5), 12);
    });
  });

  group('PolarBuildAxes rows', () {
    test('rounds the angle to the nearest five degree row', () {
      expect(PolarBuildAxes.twaRowOf(22.4), 4);
      expect(PolarBuildAxes.twaRowOf(22.5), 5);
      expect(PolarBuildAxes.twaRowOf(180), 36);
      expect(PolarBuildAxes.twaDegreesOfRow(5), 25);
    });

    test('has 37 rows and sails from 25 degrees', () {
      expect(PolarBuildAxes.twaRowCount, 37);
      expect(PolarBuildAxes.firstSailingTwaRow, 5);
    });
  });
}
