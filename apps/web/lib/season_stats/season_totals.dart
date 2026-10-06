import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
import 'package:foretack_web/season_stats/season_volume.dart';

/// Egy időszak (egy év vagy az összes) szezon-statisztikája (ADR 0049
/// Addendum 2).
@immutable
class SeasonTotals {
  /// Összesítés a három mutató-csoporttal.
  const SeasonTotals({
    required this.volume,
    required this.placings,
    required this.conditions,
  });

  /// Versenyszám, idő és táv.
  final SeasonVolume volume;

  /// Helyezések: osztály, összevont abszolút és versenyenként.
  final SeasonPlacings placings;

  /// Pálya-mutatók és szélsávok.
  final SeasonConditions conditions;
}

/// Az [entries] versenyeinek szezon-statisztikája.
SeasonTotals summarizeSeason(List<LogEntry> entries) => SeasonTotals(
  volume: summarizeSeasonVolume(entries),
  placings: summarizeSeasonPlacings(entries),
  conditions: summarizeSeasonConditions(entries),
);
