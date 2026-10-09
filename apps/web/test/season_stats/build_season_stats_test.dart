import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/log_period.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:foretack_web/season_stats/season_stats.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

void main() {
  final summaries = [
    telemetrySummary('t2026', start: DateTime(2026, 7, 26, 10)),
    manualSummary(
      'm2026',
      date: '2026-05-01',
      result: const RaceResultInput(overallPlace: FinishPlace(2)),
    ),
    manualSummary(
      'm2024',
      date: '2024-07-25',
      result: const RaceResultInput(overallPlace: FinishPlace(1)),
    ),
  ];
  final years = groupRaceLog(summaries);

  SeasonStats statsFor(LogPeriod period) =>
      buildSeasonStats(buildRaceLogView(years, period));

  group('buildSeasonStats', () {
    test('summarizes the newest year only by default', () {
      // ACT
      final stats = statsFor(const NewestYear());

      // ASSERT
      expect(stats.view.selectedYear, 2026);
      expect(stats.totals.volume.raceCount, 2);
      expect(stats.totals.placings.overallPlacings.podiums, 1);
      expect(stats.years, isEmpty);
    });

    test('summarizes a chosen year', () {
      // ACT
      final stats = statsFor(const ChosenYear(2024));

      // ASSERT
      expect(stats.totals.volume.raceCount, 1);
      expect(stats.totals.placings.overallPlacings.firsts, 1);
      expect(stats.years, isEmpty);
    });

    test('compares the years newest first for every year', () {
      // ACT
      final stats = statsFor(const AllYears());

      // ASSERT
      expect(stats.totals.volume.raceCount, 3);
      expect(stats.totals.placings.overallPlacings.podiums, 2);
      expect([for (final year in stats.years) year.year], [2026, 2024]);
      expect(stats.years.first.totals.volume.raceCount, 2);
      expect(stats.years.last.totals.volume.raceCount, 1);
    });

    test('is empty for an empty archive', () {
      // ACT
      final stats = buildSeasonStats(
        buildRaceLogView(const [], const NewestYear()),
      );

      // ASSERT
      expect(stats.totals.volume.raceCount, 0);
      expect(stats.totals.placings.raceMedals, isEmpty);
      expect(stats.years, isEmpty);
    });
  });
}
