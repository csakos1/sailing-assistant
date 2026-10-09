import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/placing_order.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';

/// A szezon helyezései: osztály és összevont abszolút (ADR 0049 Addendum
/// 2 R1, R2, R5).
@immutable
class SeasonPlacings {
  /// Helyezések a két kategóriában és versenyenként.
  const SeasonPlacings({
    required this.classPlacings,
    required this.overallPlacings,
    required this.raceMedals,
  });

  /// Osztályhelyezések.
  final PlacingTally classPlacings;

  /// Összevont abszolút helyezések: az abszolút és az egytestű jobbika.
  final PlacingTally overallPlacings;

  /// Versenyenként a jobbik helyezés érme időrendben, a legrégebbivel
  /// kezdve; `null`, ha a verseny nem dobogós.
  final List<Medal?> raceMedals;

  /// Hány versenyen volt dobogós az osztály- vagy az abszolút helyezés.
  int get podiumRaceCount => raceMedals.nonNulls.length;

  /// A dobogós helyezések száma, versenyenként legfeljebb kettő.
  int get podiumPlacings => classPlacings.podiums + overallPlacings.podiums;

  /// Az összes dobogós helyezés érme, arany, ezüst, bronz sorrendben.
  List<Medal> get harvest => [
    for (final medal in Medal.values)
      ...List.filled(
        classPlacings.countOf(medal) + overallPlacings.countOf(medal),
        medal,
      ),
  ];
}

/// Az [entries] versenyeinek helyezései.
///
/// Az [entries] a napló sorrendjében jön, a legújabbal kezdve; a
/// vitorla-sor ezért fordított sorrendben épül.
SeasonPlacings summarizeSeasonPlacings(List<LogEntry> entries) {
  final results = [
    for (final entry in entries) entry.summary.result?.content,
  ];
  final classPlaces = [for (final result in results) result?.classPlace];
  final overallPlaces = [
    for (final result in results)
      betterPlacing(result?.overallPlace, result?.monohullPlace),
  ];
  return SeasonPlacings(
    classPlacings: tallyPlacings(classPlaces),
    overallPlacings: tallyPlacings(overallPlaces),
    raceMedals: List.unmodifiable([
      for (var index = entries.length - 1; index >= 0; index--)
        Medal.of(betterPlacing(classPlaces[index], overallPlaces[index])),
    ]),
  );
}
