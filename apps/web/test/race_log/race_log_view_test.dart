import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/log_period.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

void main() {
  final summaries = [
    telemetrySummary(
      'r2026',
      start: DateTime(2026, 7, 26, 11),
      distanceMeters: 22600,
      maxSpeedMps: 4,
    ),
    manualSummary('m2026', date: '2026-08-23', distanceMeters: 9800),
    telemetrySummary(
      'r2024',
      start: DateTime(2024, 6, 1, 10),
      hours: 2,
      maxSpeedMps: 5,
    ),
  ];
  final years = groupRaceLog(summaries);

  group('buildRaceLogView selects', () {
    test('the newest year by default', () {
      final view = buildRaceLogView(years, const NewestYear());

      expect(view.selectedYear, 2026);
      expect(view.availableYears, [2026, 2024]);
      expect(view.raceCount, 2);
    });

    test('a chosen year that exists', () {
      final view = buildRaceLogView(years, const ChosenYear(2024));

      expect(view.selectedYear, 2024);
      expect(view.raceCount, 1);
    });

    test('the newest year when the chosen one is gone', () {
      final view = buildRaceLogView(years, const ChosenYear(2023));

      expect(view.selectedYear, 2026);
    });

    test('every year with no selected year', () {
      final view = buildRaceLogView(years, const AllYears());

      expect(view.isAllYears, isTrue);
      expect(view.selectedYear, isNull);
      expect(view.raceCount, 3);
    });

    test('nothing for an empty archive', () {
      final view = buildRaceLogView(const [], const NewestYear());

      expect(view.isEmpty, isTrue);
      expect(view.totals.timeOnWater, isNull);
    });
  });

  group('buildRaceLogView totals', () {
    test('add up the shown races only', () {
      // ARRANGE: 2026: a 4 oras rogzites, a kezi verseny ido nelkul
      final view = buildRaceLogView(years, const NewestYear());

      // ACT + ASSERT
      expect(view.totals.timeOnWater, const Duration(hours: 4));
      expect(view.totals.distanceMeters, 22600 + 9800);
      expect(view.totals.maxSpeedMps, 4);
    });

    test('use the official elapsed time over the recording', () {
      // ARRANGE
      final official = [
        manualSummary(
          'm1',
          date: '2026-08-23',
          result: RaceResultInput(
            officialStart: DateTime(2026, 8, 23, 10),
            officialFinish: DateTime(2026, 8, 23, 11, 30),
          ),
        ),
        telemetrySummary(
          'r1',
          start: DateTime(2026, 7, 26, 8),
          result: RaceResultInput(
            officialStart: DateTime(2026, 7, 26, 9),
            officialFinish: DateTime(2026, 7, 26, 11),
          ),
        ),
      ];

      // ACT
      final view = buildRaceLogView(
        groupRaceLog(official),
        const NewestYear(),
      );

      // ASSERT: 1:30 + 2:00, a 4 oras rogzites helyett
      expect(view.totals.timeOnWater, const Duration(hours: 3, minutes: 30));
    });

    test('cover every year when all years are shown', () {
      final view = buildRaceLogView(years, const AllYears());

      expect(view.totals.timeOnWater, const Duration(hours: 6));
      expect(view.totals.maxSpeedMps, 5);
    });
  });
}
