import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/deep_downwind_section.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_axes.dart';

void main() {
  LabSample labSample({
    required int season,
    required PolarSampleSource source,
    required double twaDeg,
    required double twsKnots,
    required double stwKnots,
    required int seconds,
  }) => LabSample(
    raceId: 'r1',
    season: season,
    source: source,
    absTwaDeg: twaDeg,
    twsKnots: twsKnots,
    stwKnots: stwKnots,
    seconds: seconds,
  );

  // VMG/TWS: 150/4/6.8 -> 1.47; 150/8/6.9 -> 0.75; 160/3/5.5 -> 1.72. A
  // 120 fokos minta nem mely hatszel, a 12 kn-os oszlop kivul esik.
  final section = deepDownwindSection(
    [
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 150,
        twsKnots: 4,
        stwKnots: 6.8,
        seconds: 600,
      ),
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 150,
        twsKnots: 8,
        stwKnots: 6.9,
        seconds: 1200,
      ),
      labSample(
        season: 2024,
        source: PolarSampleSource.legacyTrack,
        twaDeg: 160,
        twsKnots: 3,
        stwKnots: 5.5,
        seconds: 300,
      ),
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 120,
        twsKnots: 4,
        stwKnots: 6,
        seconds: 600,
      ),
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 150,
        twsKnots: 12,
        stwKnots: 8,
        seconds: 600,
      ),
    ],
    axes: PolarBuildAxes(twsColumnsKnots: PolarBuildAxes.baseTwsColumnsKnots),
    maximumRatio: 1.3,
  );

  group('deepDownwindSection', () {
    test('labels the ratio bands', () {
      expect(downwindRatioBands, [1, 1.3, 1.6]);
      expect(
        section,
        contains(
          '| Szezon | Forrás | Perc | < 1 | 1–1.3 | 1.3–1.6 | ≥ 1.6 '
          '| STW-medián a küszöb fölött (kn) |',
        ),
      );
      expect(section, contains('küszöbe: 1.3, e fölött dob'));
    });

    test('splits by season and source', () {
      expect(
        section,
        contains('| 2024 | régi napló | 5 | 0 | 0 | 0 | 5 | 5.50 |'),
      );
      expect(
        section,
        contains('| 2026 | telemetria | 30 | 20 | 0 | 10 | 0 | 6.80 |'),
      );
    });

    test('splits by wind column up to 8 knots', () {
      expect(section, contains('| 2 | 0 | 0 | 0 | 0 | 0 | · |'));
      expect(section, contains('| 3 | 5 | 0 | 0 | 0 | 5 | 5.50 |'));
      expect(section, contains('| 4 | 10 | 0 | 0 | 10 | 0 | 6.80 |'));
      expect(section, contains('| 8 | 20 | 20 | 0 | 0 | 0 | · |'));
      // Sor elejen: a szezon-sorban a 10 perc is | 10 |.
      expect(section, isNot(contains('\n| 10 | ')));
    });
  });
}
