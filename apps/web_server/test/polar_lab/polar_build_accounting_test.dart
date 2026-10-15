import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';
import 'package:web_server/src/polar_lab/polar_build_accounting.dart';
import 'package:web_server/src/polar_lab/polar_build_rejection.dart';

void main() {
  LabSample labSample({
    required int season,
    required String raceId,
    required int seconds,
    double twaDeg = 60,
    double twsKnots = 10,
    double stwKnots = 5,
  }) => LabSample(
    raceId: raceId,
    season: season,
    source: PolarSampleSource.telemetry,
    absTwaDeg: twaDeg,
    twsKnots: twsKnots,
    stwKnots: stwKnots,
    seconds: seconds,
  );

  group('PolarBuildSeasonAccounting.of', () {
    test('accounts for every second by season and reason', () {
      // ARRANGE: 2025-ben 10 mp beragadt szelirany es 35 mp nem allando
      // szel, 2026-ban egyik sincs
      final accounting = PolarBuildSeasonAccounting.of(
        allSamples: [
          labSample(season: 2026, raceId: 'c', seconds: 53),
          labSample(season: 2025, raceId: 'a', seconds: 100),
          labSample(season: 2025, raceId: 'b', seconds: 20),
        ],
        unfrozenSamples: [
          labSample(season: 2026, raceId: 'c', seconds: 53),
          labSample(season: 2025, raceId: 'a', seconds: 90),
          labSample(season: 2025, raceId: 'b', seconds: 20),
        ],
        steadySamples: [
          labSample(season: 2025, raceId: 'a', seconds: 60),
          labSample(
            season: 2025,
            raceId: 'a',
            seconds: 10,
            twaDeg: 179,
            twsKnots: 1.5,
          ),
          labSample(season: 2025, raceId: 'b', seconds: 5, stwKnots: 0.2),
          labSample(season: 2026, raceId: 'c', seconds: 50),
          labSample(season: 2026, raceId: 'c', seconds: 3, twaDeg: 20),
        ],
      );

      // ASSERT
      expect(accounting, const [
        PolarBuildSeasonAccounting(
          season: 2025,
          raceCount: 2,
          validSeconds: 120,
          frozenSeconds: 10,
          unsteadySeconds: 35,
          rejectedSeconds: {
            PolarBuildRejection.calm: 10,
            PolarBuildRejection.waterSpeed: 5,
          },
          usedSeconds: 60,
        ),
        PolarBuildSeasonAccounting(
          season: 2026,
          raceCount: 1,
          validSeconds: 53,
          frozenSeconds: 0,
          unsteadySeconds: 0,
          rejectedSeconds: {PolarBuildRejection.noGo: 3},
          usedSeconds: 50,
        ),
      ]);
    });

    test('gives nothing without samples', () {
      expect(
        PolarBuildSeasonAccounting.of(
          allSamples: [],
          unfrozenSamples: [],
          steadySamples: [],
        ),
        isEmpty,
      );
    });
  });
}
