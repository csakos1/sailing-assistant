import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:foretack_web/season_stats/season_totals.dart';

/// Egy év sora az éremtáblában (ADR 0049 Addendum 2 R3).
typedef SeasonYear = ({int year, SeasonTotals totals});

/// A Statisztika-képernyő kész állapota (ADR 0049 D2–D4, Addendum 2).
@immutable
class SeasonStats {
  /// Statisztika a [view] naplónézethez.
  const SeasonStats({
    required this.view,
    required this.totals,
    required this.years,
  });

  /// A napló nézete: az évsáv és a megjelenített versenyek forrása.
  final RaceLogView view;

  /// A megjelenített versenyek összesítése.
  final SeasonTotals totals;

  /// Az évek összevetése csökkenő sorrendben; csak „Összes év" nézetben
  /// nem üres.
  final List<SeasonYear> years;
}

/// A [view] naplónézet szezon-statisztikája.
///
/// A választott időszakot a nézet már feloldotta (P4), így a statisztika
/// pontosan a napló versenyeiből számol.
SeasonStats buildSeasonStats(RaceLogView view) => SeasonStats(
  view: view,
  totals: summarizeSeason(_entriesOf(view.shownYears)),
  years: view.isAllYears ? _yearsOf(view.shownYears) : const [],
);

List<SeasonYear> _yearsOf(List<LogYear> years) => List.unmodifiable([
  for (final year in years)
    (year: year.year, totals: summarizeSeason(_entriesOf([year]))),
]);

List<LogEntry> _entriesOf(List<LogYear> years) => [
  for (final year in years)
    for (final month in year.months) ...month.entries,
];
