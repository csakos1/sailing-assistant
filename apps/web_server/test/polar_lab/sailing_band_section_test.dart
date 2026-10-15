import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/sailing_band_section.dart';

import '../polar/polar_fixtures.dart';

void main() {
  // Az egyszeru polar celja mindenhol 5 kn, igy a % = 20 x STW (kn).
  List<LabSample> samples({
    required double twaDeg,
    required double twsKnots,
    required int seconds,
    double stwKnots = 4.5,
  }) => [
    for (var second = 0; second < seconds; second++)
      LabSample(
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        absTwaDeg: twaDeg,
        twsKnots: twsKnots,
        stwKnots: stwKnots,
        seconds: 1,
      ),
  ];

  String section(List<LabSample> labSamples) => sailingBandSection(
    title: 'T',
    note: 'N',
    samples: labSamples,
    polar: flatPolar(),
  );

  group('sailingBandSection', () {
    test('puts upwind light wind into the first column', () {
      // TWA 45 kreuz, 5 kn a 4-8-as sav; 4,5 kn -> 90%.
      expect(
        section(samples(twaDeg: 45, twsKnots: 5, seconds: 60)),
        contains('| 2026 | 90.0 (0.0) | ${_empties(8)} |'),
      );
    });

    test('puts downwind fresh wind into the last column', () {
      expect(
        section(samples(twaDeg: 150, twsKnots: 15.9, seconds: 60)),
        contains('| 2026 | ${_empties(8)} | 90.0 (0.0) |'),
      );
    });

    test('leaves out wind outside the four to sixteen knots', () {
      expect(
        section([
          ...samples(twaDeg: 45, twsKnots: 3.9, seconds: 60),
          ...samples(twaDeg: 45, twsKnots: 16, seconds: 60),
        ]),
        contains('| 2026 | ${_empties(9)} |'),
      );
    });

    test('leaves a cell empty below sixty seconds', () {
      expect(
        section(samples(twaDeg: 45, twsKnots: 5, seconds: 59)),
        contains('| 2026 | ${_empties(9)} |'),
      );
    });
  });
}

// [count] ures cella (U+00B7) a tabla elvalasztojaval.
String _empties(int count) => List.filled(count, '\u00b7').join(' | ');
