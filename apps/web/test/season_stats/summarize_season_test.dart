import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
import 'package:foretack_web/season_stats/season_totals.dart';
import 'package:foretack_web/season_stats/season_volume.dart';
import 'package:foretack_web/season_stats/wind_band.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';
import 'season_fixtures.dart';

void main() {
  final officialStart = DateTime.utc(2026, 7, 26, 9);

  group('summarizeSeasonVolume', () {
    test('adds up races, time and distance', () {
      // ARRANGE: egy 4 oras rogzites, egy kezi verseny 2 oras hivatalos
      // idovel, es egy kezi verseny ido nelkul
      final entries = [
        entryOf(
          telemetrySummary(
            't1',
            start: DateTime(2026, 7, 26, 10),
            distanceMeters: 20000,
          ),
        ),
        entryOf(
          manualSummary(
            'm1',
            date: '2026-06-01',
            distanceMeters: 15000,
            result: officialTimes(officialStart, const Duration(hours: 2)),
          ),
        ),
        entryOf(manualSummary('m2', date: '2026-05-01', distanceMeters: 5000)),
      ];

      // ACT
      final volume = summarizeSeasonVolume(entries);

      // ASSERT
      expect(volume.raceCount, 3);
      expect(volume.telemetryRaceCount, 1);
      expect(volume.manualRaceCount, 2);
      expect(volume.timeOnWater, const Duration(hours: 6));
      expect(volume.racesWithoutTime, 1);
      expect(volume.distanceMeters, 40000);
    });

    test('keeps missing time and distance apart from zero', () {
      // ACT
      final volume = summarizeSeasonVolume([
        entryOf(manualSummary('m1', date: '2026-05-01')),
      ]);

      // ASSERT
      expect(volume.timeOnWater, isNull);
      expect(volume.distanceMeters, isNull);
      expect(volume.racesWithoutTime, 1);
    });
  });

  group('summarizeSeasonPlacings', () {
    test('tallies each category from its own field', () {
      // ARRANGE
      final entries = [
        entryOf(
          manualSummary(
            'm1',
            date: '2026-05-01',
            result: const RaceResultInput(
              classPlace: FinishPlace(1),
              overallPlace: FinishPlace(12),
              monohullPlace: FinishPlace(9),
            ),
          ),
        ),
        entryOf(
          manualSummary(
            'm2',
            date: '2026-06-01',
            result: const RaceResultInput(
              classPlace: FinishPlace(2),
              overallPlace: Dnf(),
            ),
          ),
        ),
        entryOf(manualSummary('m3', date: '2026-07-01')),
      ];

      // ACT
      final placings = summarizeSeasonPlacings(entries);

      // ASSERT
      expect(placings.classPlacings.podiums, 2);
      expect(placings.classPlacings.enteredCount, 2);
      expect(placings.classPlacings.averagePlace, 1.5);
      expect(placings.overallPlacings.dnfs, 1);
      expect(placings.overallPlacings.averagePlace, 12);
      expect(placings.monohullPlacings.enteredCount, 1);
      expect(placings.monohullPlacings.podiums, 0);
    });
  });

  group('summarizeSeasonConditions', () {
    test('divides the timed distance by the timed duration', () {
      // ARRANGE: 36 km 2 ora alatt (5 m/s); a tav nelkuli verseny ideje es
      // az ido nelkuli verseny tava kimarad
      final entries = [
        entryOf(
          manualSummary(
            'm1',
            date: '2026-05-01',
            distanceMeters: 36000,
            result: officialTimes(officialStart, const Duration(hours: 2)),
          ),
        ),
        entryOf(
          telemetrySummary('t1', start: DateTime(2026, 6, 1, 10), hours: 3),
        ),
        entryOf(manualSummary('m2', date: '2026-07-01', distanceMeters: 9000)),
      ];

      // ACT
      final conditions = summarizeSeasonConditions(entries);

      // ASSERT
      expect(conditions.avgSpeedMps, closeTo(5, 1e-9));
    });

    test('has no average speed without a timed distance', () {
      // ACT
      final conditions = summarizeSeasonConditions([
        entryOf(manualSummary('m1', date: '2026-05-01', distanceMeters: 9000)),
      ]);

      // ASSERT
      expect(conditions.avgSpeedMps, isNull);
      expect(conditions.fastestRace, isNull);
      expect(conditions.windiestRace, isNull);
    });

    test('names the fastest and the windiest race with its day', () {
      // ARRANGE: a naplo sorrendje: a legujabb elol
      final entries = [
        entryOf(
          withStats(
            manualSummary('new', date: '2026-08-01'),
            enteredStats(maxSpeedMps: 4, maxWindMps: 9),
          ),
        ),
        entryOf(
          withStats(
            manualSummary('old', date: '2025-08-01'),
            enteredStats(maxSpeedMps: 5, maxWindMps: 9),
          ),
        ),
      ];

      // ACT
      final conditions = summarizeSeasonConditions(entries);

      // ASSERT: a szelrekord dontetlen, az ujabb verseny marad (P4)
      expect(conditions.fastestRace, (
        valueMps: 5.0,
        raceName: 'Kezi old',
        day: DateTime(2025, 8),
      ));
      expect(conditions.windiestRace?.raceName, 'Kezi new');
      expect(conditions.windiestRace?.day, DateTime(2026, 8));
    });

    test('counts races into the average wind bands', () {
      // ARRANGE: 3, 6, 6 es 20 kn, valamint egy szel nelkuli verseny
      RaceSummary windy(String id, double knots) => withStats(
        manualSummary(id, date: '2026-05-01'),
        enteredStats(avgWindMps: knotsToMetersPerSecond(knots)),
      );
      final entries = [
        entryOf(windy('a', 3)),
        entryOf(windy('b', 6)),
        entryOf(windy('c', 6)),
        entryOf(windy('d', 20)),
        entryOf(manualSummary('e', date: '2026-05-01')),
      ];

      // ACT
      final conditions = summarizeSeasonConditions(entries);

      // ASSERT
      expect(conditions.windBandCounts, {
        WindBand.below4: 1,
        WindBand.from4To8: 2,
        WindBand.from8To12: 0,
        WindBand.from12To16: 0,
        WindBand.from16: 1,
      });
      expect(
        conditions.windBandCounts.keys.toList(),
        WindBand.values,
        reason: 'the bands keep their order',
      );
      expect(conditions.racesWithoutWind, 1);
    });
  });

  group('summarizeSeason', () {
    test('is exact for official windows and entered numbers', () {
      // ARRANGE: hivatalos ablaku telemetria, trackes es beirt kezi
      final telemetry = telemetrySummary(
        't1',
        start: DateTime(2026, 7, 26, 10),
        result: officialTimes(officialStart, const Duration(hours: 3)),
      );
      final entries = [
        entryOf(withStats(telemetry, officialStats(distanceMeters: 30000))),
        entryOf(
          withStats(
            manualSummary('tracked', date: '2023-07-01'),
            officialStats(distanceMeters: 20000),
          ),
        ),
        entryOf(manualSummary('m1', date: '2022-07-01')),
      ];

      // ACT
      final totals = summarizeSeason(entries);

      // ASSERT
      expect(totals.hasApproximateValues, isFalse);
      expect(totals.volume.raceCount, 3);
    });

    test('is approximate when a recording window is included', () {
      // ARRANGE: a sample telemetria rogzitesi ablakos
      final entries = [
        entryOf(telemetrySummary('t1', start: DateTime(2026, 7, 26, 10))),
      ];

      // ACT + ASSERT
      expect(summarizeSeason(entries).hasApproximateValues, isTrue);
    });

    test('is approximate when only the time comes from the recording', () {
      // ARRANGE: hivatalos ablaku stat, de a menetido a rogzitesbol jon
      final entries = [
        entryOf(
          withStats(
            telemetrySummary('t1', start: DateTime(2026, 7, 26, 10)),
            officialStats(distanceMeters: 30000),
          ),
        ),
      ];

      // ACT + ASSERT
      expect(summarizeSeason(entries).hasApproximateValues, isTrue);
    });
  });
}
