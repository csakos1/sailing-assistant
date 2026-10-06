import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/speed_units.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
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
      expect(volume.timeOnWater, const Duration(hours: 6));
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
    });
  });

  group('summarizeSeasonPlacings', () {
    // A naplo sorrendje: a legujabb elol.
    final entries = [
      // osztaly 4., abszolut 12. / egytestu 2. -> abszolut ezust
      entryOf(
        placedRace(
          'aug',
          date: '2026-08-01',
          classPlace: const FinishPlace(4),
          overallPlace: const FinishPlace(12),
          monohullPlace: const FinishPlace(2),
        ),
      ),
      // osztaly 1., abszolut DNF -> egytestu nincs, abszolut DNF
      entryOf(
        placedRace(
          'jul',
          date: '2026-07-01',
          classPlace: const FinishPlace(1),
          overallPlace: const Dnf(),
        ),
      ),
      // semmi dobogo: osztaly 6., abszolut 9.
      entryOf(
        placedRace(
          'jun',
          date: '2026-06-01',
          classPlace: const FinishPlace(6),
          monohullPlace: const FinishPlace(9),
        ),
      ),
      // helyezes nelkul
      entryOf(manualSummary('may', date: '2026-05-01')),
    ];

    test('merges the overall and monohull places into the better one', () {
      // ACT
      final placings = summarizeSeasonPlacings(entries);

      // ASSERT
      expect(placings.overallPlacings.seconds, 1);
      expect(placings.overallPlacings.offPodium, const [
        FinishPlace(9),
        Dnf(),
      ]);
      expect(placings.classPlacings.firsts, 1);
      expect(placings.classPlacings.offPodium, const [
        FinishPlace(4),
        FinishPlace(6),
      ]);
    });

    test('counts podium races and placings', () {
      // ACT
      final placings = summarizeSeasonPlacings(entries);

      // ASSERT
      expect(placings.podiumRaceCount, 2);
      expect(placings.podiumPlacings, 2);
      expect(placings.harvest, [Medal.gold, Medal.silver]);
    });

    test('gives one medal per race, oldest first', () {
      // ACT
      final placings = summarizeSeasonPlacings(entries);

      // ASSERT: maj, jun, jul (osztaly 1.), aug (abszolut 2.)
      expect(placings.raceMedals, [null, null, Medal.gold, Medal.silver]);
    });

    test('counts two podium placings on one race', () {
      // ARRANGE
      final sameRace = [
        entryOf(
          placedRace(
            'both',
            date: '2026-05-01',
            classPlace: const FinishPlace(1),
            overallPlace: const FinishPlace(3),
          ),
        ),
      ];

      // ACT
      final placings = summarizeSeasonPlacings(sameRace);

      // ASSERT
      expect(placings.podiumRaceCount, 1);
      expect(placings.podiumPlacings, 2);
      expect(placings.raceMedals, [Medal.gold]);
      expect(placings.harvest, [Medal.gold, Medal.bronze]);
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

    test('names the record races with their day', () {
      // ARRANGE: a naplo sorrendje: a legujabb elol
      final entries = [
        entryOf(
          withStats(
            manualSummary('new', date: '2026-08-01'),
            enteredStats(
              distanceMeters: 30000,
              avgSpeedMps: 3,
              maxSpeedMps: 4,
              maxWindMps: 9,
            ),
          ),
        ),
        entryOf(
          withStats(
            manualSummary('old', date: '2025-08-01'),
            enteredStats(
              distanceMeters: 55900,
              avgSpeedMps: 2.5,
              maxSpeedMps: 5,
              maxWindMps: 9,
            ),
          ),
        ),
      ];

      // ACT
      final conditions = summarizeSeasonConditions(entries);

      // ASSERT: a szelrekord dontetlen, az ujabb verseny marad
      expect(conditions.longestRace, (
        value: 55900.0,
        raceName: 'Kezi old',
        day: DateTime(2025, 8),
      ));
      expect(conditions.fastestAverageRace?.raceName, 'Kezi new');
      expect(conditions.fastestRace?.raceName, 'Kezi old');
      expect(conditions.windiestRace?.raceName, 'Kezi new');
      expect(conditions.windiestRace?.day, DateTime(2026, 8));
    });

    test('has no records without measurements', () {
      // ACT
      final conditions = summarizeSeasonConditions([
        entryOf(manualSummary('m1', date: '2026-05-01')),
      ]);

      // ASSERT
      expect(conditions.avgSpeedMps, isNull);
      expect(conditions.longestRace, isNull);
      expect(conditions.fastestAverageRace, isNull);
      expect(conditions.prevailingWindPoints, isEmpty);
    });

    test('gives every tied prevailing wind point in compass order', () {
      // ARRANGE: DDNy ketszer, DDK ketszer, E egyszer
      RaceSummary from(String id, CompassPoint point) => withStats(
        manualSummary(id, date: '2026-05-01'),
        enteredStats(windPoint: point),
      );
      final entries = [
        entryOf(from('a', CompassPoint.southSouthWest)),
        entryOf(from('b', CompassPoint.north)),
        entryOf(from('c', CompassPoint.southSouthEast)),
        entryOf(from('d', CompassPoint.southSouthWest)),
        entryOf(from('e', CompassPoint.southSouthEast)),
      ];

      // ACT
      final conditions = summarizeSeasonConditions(entries);

      // ASSERT
      expect(conditions.prevailingWindPoints, [
        CompassPoint.southSouthEast,
        CompassPoint.southSouthWest,
      ]);
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
      expect(conditions.windBandCounts.keys.toList(), WindBand.values);
    });
  });
}
