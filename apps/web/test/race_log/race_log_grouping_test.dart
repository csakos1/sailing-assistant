import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

void main() {
  group('logDayOf', () {
    test('uses the local recording start of a telemetry race', () {
      // ARRANGE: a late evening start stays on its own local day
      final summary = telemetrySummary(
        'r1',
        start: DateTime(2026, 7, 30, 23, 30),
      );

      // ACT + ASSERT
      expect(logDayOf(summary), DateTime(2026, 7, 30));
    });

    test('prefers the official start when it is set', () {
      final summary = telemetrySummary(
        'r1',
        start: DateTime(2026, 7, 30, 23, 30),
        result: RaceResultInput(officialStart: DateTime(2026, 7, 31, 7)),
      );

      expect(logDayOf(summary), DateTime(2026, 7, 31));
    });

    test('uses the calendar date of a manual race', () {
      expect(
        logDayOf(manualSummary('m1', date: '2021-05-01')),
        DateTime(2021, 5),
      );
    });
  });

  group('groupRaceLog', () {
    test('groups by year and month, newest first', () {
      // ARRANGE
      final summaries = [
        manualSummary('m2021', date: '2021-05-01'),
        telemetrySummary('jul', start: DateTime(2026, 7, 26, 11)),
        telemetrySummary('aug', start: DateTime(2026, 8, 22, 11)),
        telemetrySummary('jul2', start: DateTime(2026, 7, 30, 9)),
      ];

      // ACT
      final years = groupRaceLog(summaries);

      // ASSERT
      expect(years.map((year) => year.year), [2026, 2021]);
      expect(years.first.months.map((month) => month.month), [8, 7]);
      expect(
        years.first.months.last.entries.map((entry) => entry.summary.id),
        ['jul2', 'jul'],
      );
      expect(years.first.raceCount, 3);
      expect(years.last.raceCount, 1);
    });

    test('keeps the input order within one day', () {
      // ARRANGE: a ket nap ugyanaz, a szerver sorrendje szamit
      final summaries = [
        telemetrySummary('first', start: DateTime(2026, 6, 13, 15)),
        telemetrySummary('second', start: DateTime(2026, 6, 13, 9)),
      ];

      // ACT
      final entries = groupRaceLog(summaries).single.months.single.entries;

      // ASSERT
      expect(entries.map((entry) => entry.summary.id), ['first', 'second']);
    });

    test('returns nothing for an empty archive', () {
      expect(groupRaceLog(const []), isEmpty);
    });
  });
}
