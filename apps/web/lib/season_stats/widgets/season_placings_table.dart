import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
import 'package:foretack_web/season_stats/widgets/season_table.dart';

/// A HELYEZÉSEK táblája: soronként egy kategória (ADR 0049 D3 2.,
/// Addendum 1 P2).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonPlacingsTable extends StatelessWidget {
  /// A [placings] táblája; a MEGADVA a [raceCount]-hoz viszonyít.
  const SeasonPlacingsTable({
    required this.placings,
    required this.raceCount,
    super.key,
  });

  /// A helyezések kategóriánként.
  final SeasonPlacings placings;

  /// A megjelenített versenyek száma.
  final int raceCount;

  static const double _countWidth = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    SeasonTableColumn count(String label) =>
        (label: label, unit: null, width: _countWidth, isNumeric: true);
    return SeasonTable(
      columns: [
        (label: '', unit: null, width: null, isNumeric: false),
        count(l10n.statsColumnFirst),
        count(l10n.statsColumnSecond),
        count(l10n.statsColumnThird),
        count(l10n.statsColumnPodiumCaps),
        count(l10n.statsColumnDnfCaps),
        count(l10n.statsColumnDsqCaps),
        count(l10n.statsColumnAverageCaps),
        count(l10n.statsColumnEnteredCaps),
      ],
      rows: [
        _row(l10n, l10n.statsRowClass, placings.classPlacings),
        _row(l10n, l10n.statsRowOverall, placings.overallPlacings),
        _row(l10n, l10n.statsRowMonohull, placings.monohullPlacings),
      ],
    );
  }

  List<String> _row(
    WebLocalizations l10n,
    String category,
    PlacingTally tally,
  ) {
    final average = tally.averagePlace;
    return [
      category,
      '${tally.firsts}',
      '${tally.seconds}',
      '${tally.thirds}',
      '${tally.podiums}',
      '${tally.dnfs}',
      '${tally.dsqs}',
      if (average == null) missingValueLabel else formatAveragePlace(average),
      l10n.statsEnteredOf(tally.enteredCount, raceCount),
    ];
  }
}
