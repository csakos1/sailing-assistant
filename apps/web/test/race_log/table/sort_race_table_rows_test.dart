import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';
import 'package:foretack_web/race_log/table/sort_direction.dart';
import 'package:foretack_web/race_log/table/sort_race_table_rows.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../../support/sample_summaries.dart';

RaceTableRow manualRow(
  String id, {
  String date = '2026-07-26',
  RaceResultInput? result,
  double? distanceMeters,
}) {
  final summary = manualSummary(
    id,
    date: date,
    result: result,
    distanceMeters: distanceMeters,
  );
  return raceTableRowOf(LogEntry(summary: summary, day: logDayOf(summary)));
}

List<String> idsOf(List<RaceTableRow> rows) => [
  for (final row in rows) row.summary.id,
];

RaceTableSort sortBy(RaceTableColumn column, SortDirection direction) =>
    RaceTableSort(column: column, direction: direction);

void main() {
  group('sortRaceTableRows by date', () {
    test('puts the newest first when descending', () {
      final rows = [
        manualRow('a', date: '2024-07-25'),
        manualRow('b', date: '2026-08-22'),
        manualRow('c', date: '2025-06-14'),
      ];

      final sorted = sortRaceTableRows(rows, RaceTableSort.initial);

      expect(idsOf(sorted), ['b', 'c', 'a']);
    });

    test('keeps the input order of races on the same day', () {
      final rows = [
        manualRow('first', date: '2026-06-13'),
        manualRow('second', date: '2026-06-13'),
      ];

      final ascending = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.date, SortDirection.ascending),
      );

      expect(idsOf(ascending), ['first', 'second']);
    });
  });

  group('sortRaceTableRows by placing', () {
    final rows = [
      manualRow(
        'empty',
        result: const RaceResultInput(prize: 'semmi'),
      ),
      manualRow('dsq', result: const RaceResultInput(overallPlace: Dsq())),
      manualRow(
        'third',
        result: const RaceResultInput(overallPlace: FinishPlace(3)),
      ),
      manualRow('dnf', result: const RaceResultInput(overallPlace: Dnf())),
      manualRow(
        'first',
        result: const RaceResultInput(overallPlace: FinishPlace(1)),
      ),
    ];

    test('puts DNF, then DSQ, then empty after the places', () {
      final sorted = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.overallPlace, SortDirection.ascending),
      );

      expect(idsOf(sorted), ['first', 'third', 'dnf', 'dsq', 'empty']);
    });

    test('keeps the missing ones at the end when reversed', () {
      final sorted = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.overallPlace, SortDirection.descending),
      );

      expect(idsOf(sorted), ['third', 'first', 'dnf', 'dsq', 'empty']);
    });
  });

  group('sortRaceTableRows by quantity and text', () {
    test('puts a missing distance last in both directions', () {
      final rows = [
        manualRow('none'),
        manualRow('short', distanceMeters: 9800),
        manualRow('long', distanceMeters: 172300),
      ];

      final descending = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.distance, SortDirection.descending),
      );
      final ascending = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.distance, SortDirection.ascending),
      );

      expect(idsOf(descending), ['long', 'short', 'none']);
      expect(idsOf(ascending), ['short', 'long', 'none']);
    });

    test('sorts the start by the time of day, not by the date', () {
      // Given: a korabbi napon kesobb indult verseny.
      final rows = [
        manualRow(
          'early-day-late-start',
          date: '2024-07-25',
          result: RaceResultInput(officialStart: DateTime(2024, 7, 25, 11)),
        ),
        manualRow(
          'late-day-early-start',
          date: '2026-07-30',
          result: RaceResultInput(officialStart: DateTime(2026, 7, 30, 9)),
        ),
      ];

      final ascending = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.start, SortDirection.ascending),
      );

      expect(idsOf(ascending), [
        'late-day-early-start',
        'early-day-late-start',
      ]);
    });

    test('sorts the names ignoring case', () {
      // A minta neve "Kezi <id>", igy a nev az id-t koveti.
      final rows = [manualRow('b'), manualRow('A'), manualRow('c')];

      final sorted = sortRaceTableRows(
        rows,
        sortBy(RaceTableColumn.name, SortDirection.ascending),
      );

      expect(idsOf(sorted), ['A', 'b', 'c']);
    });
  });
}
