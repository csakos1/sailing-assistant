import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:foretack_web/race_log/table/race_table_column.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:foretack_web/race_log/table/race_table_sort.dart';
import 'package:foretack_web/race_log/table/sort_race_table_rows.dart';

/// A táblázat törzsének egy sora: évsor vagy verseny (ADR 0048 Addendum 1
/// G2, Addendum 4 K27).
@immutable
sealed class RaceTableItem {
  const RaceTableItem();
}

/// Évhatár dátum szerinti rendezésnél: az év és a versenyei száma.
final class TableYearItem extends RaceTableItem {
  /// Évsor a [year] évhez, [raceCount] versennyel.
  const TableYearItem({required this.year, required this.raceCount});

  /// Az év.
  final int year;

  /// Az év versenyeinek száma a táblázatban.
  final int raceCount;
}

/// Egy verseny sora a csíkozás indexével.
final class TableRaceItem extends RaceTableItem {
  /// A [row] verseny a [stripeIndex]-edik helyen.
  const TableRaceItem({required this.row, required this.stripeIndex});

  /// A verseny cellái.
  final RaceTableRow row;

  /// A csíkozás indexe: dátum szerinti rendezésnél évenként nulláról
  /// indul, más rendezésnél folyamatos.
  final int stripeIndex;

  /// Igaz a páros sorokon (1., 3., … index): ezek kapják a második
  /// sorszínt, így minden év páratlan sorral indul.
  bool get isAlternate => stripeIndex.isOdd;
}

/// A [view] megjelenített versenyei táblázat-sorokként, a [sort] szerint.
///
/// Az időszak a Lista nézettel közös (14w): a táblázat ugyanazokat a
/// versenyeket mutatja.
List<RaceTableItem> raceTableItemsOf(RaceLogView view, RaceTableSort sort) {
  final rows = [
    for (final year in view.shownYears)
      for (final month in year.months)
        for (final entry in month.entries) raceTableRowOf(entry),
  ];
  return buildRaceTableItems(sortRaceTableRows(rows, sort), sort.column);
}

/// A rendezett [rows] sorlistája: évsorok csak a [sortColumn] dátum
/// esetén (G2).
///
/// Dátum szerinti rendezésnél egy év sorai egymás után állnak, mindkét
/// irányban, ezért egy év egyetlen évsort kap.
List<RaceTableItem> buildRaceTableItems(
  List<RaceTableRow> rows,
  RaceTableColumn sortColumn,
) {
  if (sortColumn != RaceTableColumn.date) {
    return List.unmodifiable([
      for (final (index, row) in rows.indexed)
        TableRaceItem(row: row, stripeIndex: index),
    ]);
  }

  final countsByYear = <int, int>{};
  for (final row in rows) {
    countsByYear.update(row.day.year, (count) => count + 1, ifAbsent: () => 1);
  }
  final items = <RaceTableItem>[];
  int? currentYear;
  var stripeIndex = 0;
  for (final row in rows) {
    final year = row.day.year;
    if (year != currentYear) {
      // A `!` biztonságos: minden sor éve bekerült a számlálóba.
      items.add(TableYearItem(year: year, raceCount: countsByYear[year]!));
      currentYear = year;
      stripeIndex = 0;
    }
    items.add(TableRaceItem(row: row, stripeIndex: stripeIndex));
    stripeIndex++;
  }
  return List.unmodifiable(items);
}
