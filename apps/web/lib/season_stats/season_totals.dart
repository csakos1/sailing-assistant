import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
import 'package:foretack_web/season_stats/season_volume.dart';

/// Egy időszak (egy év vagy az összes) szezon-statisztikája (ADR 0049
/// D3, Addendum 1 P4).
@immutable
class SeasonTotals {
  /// Összesítés a három mutató-csoporttal.
  const SeasonTotals({
    required this.volume,
    required this.placings,
    required this.conditions,
    required this.hasApproximateValues,
  });

  /// Versenyszám, idő és táv.
  final SeasonVolume volume;

  /// Helyezések kategóriánként.
  final SeasonPlacings placings;

  /// Sebesség és szél.
  final SeasonConditions conditions;

  /// Igaz, ha valamelyik verseny statja a teljes rögzítésből, vagy az
  /// ideje a rögzítés hosszából jön (K9).
  final bool hasApproximateValues;
}

/// Az [entries] versenyeinek szezon-statisztikája.
SeasonTotals summarizeSeason(List<LogEntry> entries) => SeasonTotals(
  volume: summarizeSeasonVolume(entries),
  placings: summarizeSeasonPlacings(entries),
  conditions: summarizeSeasonConditions(entries),
  hasApproximateValues: entries.any(_isApproximate),
);

bool _isApproximate(LogEntry entry) =>
    entry.summary.stats.window.isApproximate ||
    (elapsedTimeOf(entry.summary)?.isApproximate ?? false);
