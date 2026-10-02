import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/log_period.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_items.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';

import '../../support/sample_summaries.dart';

RaceTableRow manualRow(String id, String date, {double? distanceMeters}) {
  final summary = manualSummary(
    id,
    date: date,
    distanceMeters: distanceMeters,
  );
  return raceTableRowOf(LogEntry(summary: summary, day: logDayOf(summary)));
}

// A sorlista rovid leirasa: evsor "Y2026/2", versenysor "id#csik".
List<String> itemLabels(List<RaceTableItem> items) => [
  for (final item in items)
    switch (item) {
      TableYearItem(:final year, :final raceCount) => 'Y$year/$raceCount',
      TableRaceItem(:final row, :final stripeIndex) =>
        '${row.summary.id}#$stripeIndex',
    },
];

void main() {
  group('RaceTableSort.afterTapOn', () {
    test('starts a quantity column descending', () {
      final sort = RaceTableSort.initial.afterTapOn(RaceTableColumn.maxWind);

      expect(sort.column, RaceTableColumn.maxWind);
      expect(sort.direction, SortDirection.descending);
    });

    test('starts a placing or text column ascending', () {
      final byPlace = RaceTableSort.initial.afterTapOn(
        RaceTableColumn.overallPlace,
      );
      expect(byPlace.direction, SortDirection.ascending);
      expect(
        RaceTableSort.initial.afterTapOn(RaceTableColumn.name).direction,
        SortDirection.ascending,
      );
    });

    test('reverses the direction on the same column', () {
      final sort = RaceTableSort.initial.afterTapOn(RaceTableColumn.date);

      expect(sort.column, RaceTableColumn.date);
      expect(sort.direction, SortDirection.ascending);
    });
  });

  group('buildRaceTableItems', () {
    final rows = [
      manualRow('a', '2026-08-22'),
      manualRow('b', '2026-07-30'),
      manualRow('c', '2025-10-19'),
    ];

    test('adds a year row and restarts the stripes by date', () {
      final items = buildRaceTableItems(rows, RaceTableColumn.date);

      expect(itemLabels(items), ['Y2026/2', 'a#0', 'b#1', 'Y2025/1', 'c#0']);
    });

    test('has no year rows and continuous stripes for other columns', () {
      final items = buildRaceTableItems(rows, RaceTableColumn.distance);

      expect(itemLabels(items), ['a#0', 'b#1', 'c#2']);
    });

    test('marks every second race row as the alternate colour', () {
      final items = buildRaceTableItems(rows, RaceTableColumn.name);

      expect(
        [for (final item in items) (item as TableRaceItem).isAlternate],
        [
          false,
          true,
          false,
        ],
      );
    });
  });

  group('raceTableItemsOf', () {
    test('shows the races of the chosen period, sorted', () {
      // ARRANGE: harom ev, az osszes ev valasztva.
      final years = groupRaceLog([
        manualSummary('old', date: '2024-07-25', distanceMeters: 172300),
        manualSummary('new', date: '2026-08-22', distanceMeters: 9800),
        manualSummary('mid', date: '2025-06-14', distanceMeters: 30900),
      ]);
      final view = buildRaceLogView(years, const AllYears());
      const byDistance = RaceTableSort(
        column: RaceTableColumn.distance,
        direction: SortDirection.descending,
      );

      // ACT
      final items = raceTableItemsOf(view, byDistance);

      // ASSERT
      expect(itemLabels(items), ['old#0', 'mid#1', 'new#2']);
    });

    test('keeps to the newest year by default', () {
      final years = groupRaceLog([
        manualSummary('old', date: '2025-06-14'),
        manualSummary('new', date: '2026-08-22'),
      ]);
      final view = buildRaceLogView(years, const NewestYear());

      final items = raceTableItemsOf(view, RaceTableSort.initial);

      expect(itemLabels(items), ['Y2026/1', 'new#0']);
    });
  });
}
