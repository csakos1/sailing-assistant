import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_items.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_widths.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../../support/sample_summaries.dart';

// A teszt-betu minden jele egy em szeles, ezert a tesztek a merest
// relativan nezik: minimum, novekedes, felso korlat. A fejlec egyetlen
// betu, hogy a cellak tartalma dontson, ne a felirat.

List<RaceTableItem> itemsOf(List<RaceSummary> summaries) => [
  for (final (index, summary) in summaries.indexed)
    TableRaceItem(
      row: raceTableRowOf(LogEntry(summary: summary, day: logDayOf(summary))),
      stripeIndex: index,
    ),
];

RaceTableWidths measure(List<RaceTableItem> items) => measureRaceTableWidths(
  items: items,
  headerLabel: (_) => 'H',
  unitLabel: (column) => column == RaceTableColumn.distance ? 'km' : null,
  manualLabel: 'KEZI',
  nextDayMark: '+1',
  textScaler: TextScaler.noScaling,
);

void main() {
  testWidgets('never goes below the G2 widths', (tester) async {
    final widths = measure(const []);

    for (final column in RaceTableColumn.values) {
      expect(
        widths.columns[column],
        greaterThanOrEqualTo(raceTableMinimumWidths[column]!),
        reason: column.name,
      );
    }
  });

  testWidgets('widens a column to its longest value', (tester) async {
    // ARRANGE: egy rovid es egy hosszu tav.
    final short = measure(
      itemsOf([manualSummary('a', date: '2026-07-26', distanceMeters: 9800)]),
    );
    final long = measure(
      itemsOf([
        manualSummary('a', date: '2026-07-26', distanceMeters: 9800),
        manualSummary('b', date: '2026-07-30', distanceMeters: 172300),
      ]),
    );

    // ASSERT
    expect(
      long.columns[RaceTableColumn.distance],
      greaterThan(short.columns[RaceTableColumn.distance]!),
    );
  });

  testWidgets('caps the name column', (tester) async {
    final summary = manualSummary(
      '${'nagyon hosszu nev ' * 20}x',
      date: '2026-07-26',
    );

    final widths = measure(itemsOf([summary]));

    expect(widths.columns[RaceTableColumn.name], raceTableMaxNameWidth);
  });

  testWidgets('sizes the fleet slot for a three-digit fleet', (tester) async {
    // ARRANGE
    final small = measure(
      itemsOf([
        manualSummary(
          'a',
          date: '2026-07-26',
          result: const RaceResultInput(
            overallPlace: FinishPlace(3),
            overallFleetSize: 9,
          ),
        ),
      ]),
    );
    final large = measure(
      itemsOf([
        manualSummary(
          'a',
          date: '2026-07-30',
          result: const RaceResultInput(
            overallPlace: FinishPlace(20),
            overallFleetSize: 458,
          ),
        ),
      ]),
    );

    // ASSERT: a "/458" szelesebb helyet kap, mint a "/9".
    final smallSlots = small.placingSlots[RaceTableColumn.overallPlace]!;
    final largeSlots = large.placingSlots[RaceTableColumn.overallPlace]!;
    expect(largeSlots.fleet, greaterThan(smallSlots.fleet));
    expect(largeSlots.place, greaterThanOrEqualTo(smallSlots.place));
  });

  test('writes DNF and DSQ in place of the number', () {
    expect(tablePlaceText(const FinishPlace(12)), '12');
    expect(tablePlaceText(const Dnf()), 'DNF');
    expect(tablePlaceText(const Dsq()), 'DSQ');
  });
}
