import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';

/// A szezon helyezései a három kategóriában (ADR 0049 D3 2., Addendum 1
/// P2).
@immutable
class SeasonPlacings {
  /// Helyezések kategóriánként.
  const SeasonPlacings({
    required this.classPlacings,
    required this.overallPlacings,
    required this.monohullPlacings,
  });

  /// Osztályhelyezések.
  final PlacingTally classPlacings;

  /// Abszolút helyezések.
  final PlacingTally overallPlacings;

  /// Egytestű helyezések.
  final PlacingTally monohullPlacings;
}

/// Az [entries] versenyeinek helyezései kategóriánként.
SeasonPlacings summarizeSeasonPlacings(List<LogEntry> entries) {
  final results = [
    for (final entry in entries) entry.summary.result?.content,
  ];
  return SeasonPlacings(
    classPlacings: tallyPlacings([
      for (final result in results) result?.classPlace,
    ]),
    overallPlacings: tallyPlacings([
      for (final result in results) result?.overallPlace,
    ]),
    monohullPlacings: tallyPlacings([
      for (final result in results) result?.monohullPlace,
    ]),
  );
}
