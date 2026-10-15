import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/raw_polar_grid.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';

void main() {
  LabSample labSample({
    required double twaDeg,
    required int seconds,
    double twsKnots = 10,
    double stwKnots = 6,
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

  SmoothedPolarGrid smoothedOf(
    List<LabSample> samples, {
    PolarSmoothingParameters parameters = const PolarSmoothingParameters(),
  }) => SmoothedPolarGrid.of(
    RawPolarGrid.of(samples, axes: axes),
    parameters: parameters,
  );

  // Oszlopok: 0 = 2 kn, 6 = 8 kn, 7 = 10 kn, 11 = 20 kn. Sorok: 8 = 40 fok,
  // 9 = 45 fok, 10 = 50 fok, 12 = 60 fok.
  const tenKnots = 7;

  group('SmoothedPolarGrid', () {
    test('fills the row along the wind and leaves other rows empty', () {
      // ARRANGE: a 10 kn-os oszlop 40-60 fokig mert, 6 kn
      final grid = smoothedOf([
        for (final twaDeg in <double>[40, 45, 50, 55, 60])
          labSample(twaDeg: twaDeg, seconds: 400),
      ]);

      // ASSERT: mert cella, horgony alul, tartas felul, ures mashol
      expect(grid.valueAt(8, tenKnots), closeTo(6, 1e-9));
      expect(grid.originAt(8, tenKnots), PolarCellOrigin.measured);
      expect(grid.valueAt(8, 0), closeTo(1.2, 1e-9));
      expect(grid.originAt(8, 0), PolarCellOrigin.filledAlongTws);
      expect(grid.valueAt(8, 11), closeTo(6, 1e-9));
      expect(grid.valueAt(7, tenKnots), isNull);
      expect(grid.originAt(7, tenKnots), PolarCellOrigin.empty);
      expect(grid.rows.first, everyElement(isNull));
      expect(grid.rows, hasLength(PolarBuildAxes.twaRowCount));
    });

    test('smooths over a cell with too little time', () {
      final samples = [
        labSample(twaDeg: 40, seconds: 400),
        labSample(twaDeg: 45, seconds: 200, stwKnots: 9),
        labSample(twaDeg: 50, seconds: 400),
      ];

      final strict = smoothedOf(samples);
      final loose = smoothedOf(
        samples,
        parameters: const PolarSmoothingParameters(minimumMeasuredSeconds: 200),
      );

      // 300 mp alatt a 45 fokos cella nem mert: a ket szomszed egyenese.
      expect(strict.valueAt(9, tenKnots), closeTo(6, 1e-9));
      expect(strict.originAt(9, tenKnots), PolarCellOrigin.smoothedAlongTwa);
      // 200 mp-tol mert, es harom pontra a parabola pontosan illeszkedik.
      expect(loose.valueAt(9, tenKnots), closeTo(9, 1e-9));
      expect(loose.originAt(9, tenKnots), PolarCellOrigin.measured);
    });

    test('pools a target that drops in stronger wind', () {
      // ARRANGE: 60 fokon 8 kn szelben 7 kn, 10 kn szelben 6 kn
      final grid = smoothedOf([
        labSample(twaDeg: 60, seconds: 1000, twsKnots: 8, stwKnots: 7),
        labSample(twaDeg: 60, seconds: 1000),
      ]);

      // ASSERT: a ket cella az egyenlo sulyu atlagra all, utana a horgony
      expect(grid.valueAt(12, 6), closeTo(6.5, 1e-9));
      expect(grid.valueAt(12, tenKnots), closeTo(6.5, 1e-9));
      expect(grid.valueAt(12, 0), closeTo(1.625, 1e-9));
    });
  });
}
