import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/raw_polar_grid.dart';

void main() {
  LabSample labSample({
    double twaDeg = 60,
    double twsKnots = 10,
    double stwKnots = 5,
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

  final axes = PolarBuildAxes(
    twsColumnsKnots: PolarBuildAxes.baseTwsColumnsKnots,
  );
  // A 60 fokos sor es a 10 csomos oszlop.
  const row = 12;
  const column = 7;

  group('RawPolarGrid', () {
    test('sums the seconds and takes the exact weighted p90', () {
      final grid = RawPolarGrid.of([
        labSample(stwKnots: 6, seconds: 2),
        labSample(seconds: 8),
      ], axes: axes);

      // 8 mp 5 kn-on: a 90%-hoz (9 mp) a 6 kn-os minta is kell.
      expect(
        grid.cellAt(row, column),
        const RawPolarCell(seconds: 10, p90Knots: 6),
      );
    });

    test('stops at the speed that reaches ninety percent', () {
      final grid = RawPolarGrid.of([
        labSample(stwKnots: 6),
        labSample(seconds: 9),
      ], axes: axes);

      expect(grid.cellAt(row, column)?.p90Knots, 5);
    });

    test('puts a sample into its nearest row and column', () {
      final grid = RawPolarGrid.of([
        labSample(twaDeg: 62.4, twsKnots: 10.99),
      ], axes: axes);

      expect(grid.cellAt(row, column)?.seconds, 1);
      expect(grid.cellAt(row + 1, column), isNull);
      expect(grid.cellAt(row, column + 1), isNull);
    });

    test('leaves out the no-go rows and the wind below one knot', () {
      final grid = RawPolarGrid.of([
        labSample(twaDeg: 20),
        labSample(twsKnots: 0.5),
      ], axes: axes);

      expect(grid.cellAt(4, column), isNull);
      for (var anyRow = 0; anyRow < PolarBuildAxes.twaRowCount; anyRow++) {
        expect(grid.cellAt(anyRow, 0), isNull);
      }
    });
  });
}
