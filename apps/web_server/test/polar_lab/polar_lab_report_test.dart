import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_lab_report.dart';

import '../polar/polar_fixtures.dart';

void main() {
  // 120 mp a fokusz-szezonban: TWA 60, TWS 10,5 kn, STW 4,02 kn. Az
  // egyszeru polar celja mindenhol 5 kn, igy a % = 80,4.
  final samples = [
    for (var second = 0; second < 120; second++)
      const LabSample(
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        absTwaDeg: 60,
        twsKnots: 10.5,
        stwKnots: 4.02,
        seconds: 1,
      ),
    const LabSample(
      raceId: 'l1',
      season: 2024,
      source: PolarSampleSource.legacyTrack,
      absTwaDeg: 120,
      twsKnots: 6.5,
      stwKnots: 5,
      seconds: 10,
    ),
  ];

  String report() => polarLabReport(
    samples: samples,
    polar: flatPolar(),
    focusSeason: 2026,
    polarLabel: 'test.pol',
  );

  group('polarLabReport', () {
    test('lists every season with its races and hours', () {
      expect(report(), contains('| 2024 | 0 / 1 | 0.0 |'));
      expect(report(), contains('| 2026 | 1 / 0 | 0.0 |'));
    });

    test('measures the focus season against the polar', () {
      expect(report(), contains('| 2026 | 0.0 | 80.4 | 80.4 | 80.4 | 0% |'));
    });

    test('shows the p90 and its ratio in the focus grid', () {
      final text = report();

      // A 4,02 kn a 4,00-4,05 res; a kozepe 4,025 -> "4.03", a celhoz 80,5%.
      expect(text, contains('| 60 | 2 |'));
      expect(text, contains('| 60 | 4.03 |'));
      expect(text, contains('| 60 | 81 |'));
    });

    test('reports no irregular cells for a flat polar', () {
      expect(report(), contains('(> 0.1 kn): 0 '));
    });

    test('counts the calm samples at 180 degrees per season', () {
      expect(report(), contains('| 2026 | 0 | 0% |'));
    });

    test('splits the performance by sailing angle and wind band', () {
      // A TWA 60 felszel, a 10,5 kn a 8-12-es sav (az 5. oszlop).
      expect(
        report(),
        contains('| 2026 | ${_empties(4)} | 80.4 (0.0) | ${_empties(4)} |'),
      );
    });

    test('adds the smoothed table only when smoothed samples are given', () {
      final smoothed = polarLabReport(
        samples: samples,
        polar: flatPolar(),
        focusSeason: 2026,
        polarLabel: 'test.pol',
        smoothedSamples: samples,
      );

      expect(report(), isNot(contains('## 7.')));
      expect(smoothed, contains('## 7.'));
    });

    test('is the same for the same input', () {
      expect(report(), report());
    });
  });
}

// [count] ures cella (U+00B7) a tabla elvalasztojaval.
String _empties(int count) => List.filled(count, '\u00b7').join(' | ');
