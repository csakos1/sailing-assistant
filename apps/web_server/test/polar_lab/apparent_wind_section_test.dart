import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/apparent_wind_section.dart';
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

  // A szamolt AWA: 150/2/6.8 -> 11.2 fok, 40/2/3.4 -> 14.6 fok (gyanus);
  // 150/10/7 -> 108 fok, 45/10/6 -> 28 fok (rendes).
  final section = apparentWindSection(
    [
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 150,
        twsKnots: 2,
        stwKnots: 6.8,
        seconds: 600,
      ),
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 150,
        twsKnots: 10,
        stwKnots: 7,
        seconds: 600,
      ),
      labSample(
        season: 2024,
        source: PolarSampleSource.legacyTrack,
        twaDeg: 45,
        twsKnots: 10,
        stwKnots: 6,
        seconds: 1200,
      ),
      labSample(
        season: 2026,
        source: PolarSampleSource.telemetry,
        twaDeg: 40,
        twsKnots: 2,
        stwKnots: 3.4,
        seconds: 300,
      ),
    ],
    axes: PolarBuildAxes(twsColumnsKnots: PolarBuildAxes.baseTwsColumnsKnots),
  );

  group('apparentWindSection', () {
    test('labels the bands of the suspicious angles', () {
      expect(suspiciousBandsDegrees, [10, 15, 20]);
      expect(section, contains('20° alatt'));
      expect(
        section,
        contains(
          '| Szezon | Forrás | Kreuz | < 10° | 10–15° | 15–20° '
          '| Hátszél | < 10° | 10–15° | 15–20° | STW-medián (kn) |',
        ),
      );
    });

    test('splits by season and source in order', () {
      const legacy =
          '| 2024 | régi napló | 20 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | · |';
      const telemetry =
          '| 2026 | telemetria | 5 | 0 | 5 | 0 | 20 | 0 | 10 | 0 | 6.80 |';

      expect(section, contains(legacy));
      expect(section, contains(telemetry));
      expect(section.indexOf(legacy), lessThan(section.indexOf(telemetry)));
    });

    test('splits by wind column', () {
      expect(
        section,
        contains('| 2 | 5 | 0 | 5 | 0 | 10 | 0 | 10 | 0 | 6.80 |'),
      );
      expect(section, contains('| 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | · |'));
      expect(section, contains('| 10 | 20 | 0 | 0 | 0 | 10 | 0 | 0 | 0 | · |'));
    });
  });
}
