import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';
import 'package:web_server/src/polar_lab/polar_file_text.dart';
import 'package:web_server/src/polar_lab/raw_polar_grid.dart';
import 'package:web_server/src/polar_lab/smoothed_polar_grid.dart';

void main() {
  // A 10 kn-os oszlop 60 fokos sora 6.004 kn: kerekitve 6.00.
  final grid = SmoothedPolarGrid.of(
    RawPolarGrid.of(
      const [
        LabSample(
          raceId: 'r1',
          season: 2026,
          source: PolarSampleSource.telemetry,
          absTwaDeg: 60,
          twsKnots: 10,
          stwKnots: 6.004,
          seconds: 600,
        ),
      ],
      axes: PolarBuildAxes(
        twsColumnsKnots: PolarBuildAxes.baseTwsColumnsKnots,
      ),
    ),
  );

  group('polarFileText', () {
    test('writes the header and the empty rows in the dialect', () {
      final lines = polarFileText(grid).split('\n');

      expect(lines.first, 'TWA/TWS;2;3;4;5;6;7;8;10;12;14;16;20');
      expect(lines[1], '0;${List.filled(12, '0.00').join(';')}');
      expect(lines, hasLength(PolarBuildAxes.twaRowCount + 2));
      expect(lines.last, isEmpty);
    });

    test('writes two decimals and the anchor below the measured column', () {
      final row60 = polarFileText(grid).split('\n')[13];

      // 2 kn: 6.004 x 2 / 10 = 1.2008
      expect(row60, startsWith('60;1.20;1.80;2.40;'));
      expect(row60, endsWith(';6.00;6.00;6.00;6.00;6.00'));
    });

    test('reads back with the phone parser', () {
      final Polar polar;
      switch (parseForetackPolar(polarFileText(grid))) {
        case Ok(:final value):
          polar = value;
        case Err(:final error):
          fail('nem olvashato vissza: $error');
      }

      expect(polar.twsAxis, PolarBuildAxes.baseTwsColumnsKnots);
      expect(polar.twaAxis, hasLength(PolarBuildAxes.twaRowCount));
      expect(polar.grid[12][7], 6);
      expect(polar.grid[11][7], isNull);
    });
  });
}
