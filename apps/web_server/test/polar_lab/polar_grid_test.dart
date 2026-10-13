import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_grid.dart';

void main() {
  LabSample labSample({
    double twaDeg = 60,
    double twsKnots = 10.5,
    double stwKnots = 5.02,
    int seconds = 1,
  }) => LabSample(
    raceId: 'r1',
    season: 2026,
    source: PolarSampleSource.telemetry,
    absTwaDeg: twaDeg,
    twsKnots: twsKnots,
    stwKnots: stwKnots,
    seconds: seconds,
  );

  group('PolarGrid.keyOf', () {
    test('rounds the angle to the five degree row', () {
      expect(PolarGrid.keyOf(twaDeg: 62.4, twsKnots: 10).twaDeg, 60);
      expect(PolarGrid.keyOf(twaDeg: 62.6, twsKnots: 10).twaDeg, 65);
    });

    test('puts the wind into its one knot bucket by the lower bound', () {
      expect(PolarGrid.keyOf(twaDeg: 60, twsKnots: 3.99).twsColumn, 3);
      expect(PolarGrid.keyOf(twaDeg: 60, twsKnots: 4).twsColumn, 4);
    });

    test('puts strong wind into the top column', () {
      expect(
        PolarGrid.keyOf(twaDeg: 60, twsKnots: 40).twsColumn,
        PolarGrid.maxTwsColumn,
      );
    });
  });

  group('PolarGrid', () {
    const key = (twaDeg: 60, twsColumn: 10);

    test('sums the seconds of a cell', () {
      final grid = PolarGrid.of([
        labSample(seconds: 10),
        labSample(seconds: 5),
      ]);

      expect(grid.secondsAt(key), 15);
      expect(grid.twaRows, [60]);
      expect(grid.twsColumns, [10]);
    });

    test('gives nothing for an empty cell', () {
      final grid = PolarGrid.of([labSample()]);
      const emptyKey = (twaDeg: 90, twsColumn: 10);

      expect(grid.secondsAt(emptyKey), 0);
      expect(grid.stwPercentileAt(emptyKey, 0.9), isNull);
    });

    test('weights the percentile by time', () {
      // ARRANGE: 9 mp 5,02 kn-on es 1 mp 7,02 kn-on
      final grid = PolarGrid.of([
        labSample(seconds: 9),
        labSample(stwKnots: 7.02),
      ]);

      // ACT / ASSERT: a res kozepe jon vissza
      expect(grid.stwPercentileAt(key, 0.9), closeTo(5.025, 1e-9));
      expect(grid.stwPercentileAt(key, 0.95), closeTo(7.025, 1e-9));
    });
  });
}
