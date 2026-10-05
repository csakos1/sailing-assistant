import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/season_stats.dart';
import 'package:foretack_web/season_stats/widgets/season_table.dart';

/// Az ÉVEK táblája „Összes év" nézetben (ADR 0049 D3 4., Addendum 1 P5).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonYearsTable extends StatelessWidget {
  /// A [years] évek táblája, a megadott sorrendben.
  const SeasonYearsTable({required this.years, super.key});

  /// Az évek, csökkenő sorrendben.
  final List<SeasonYear> years;

  static const double _valueWidth = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    SeasonTableColumn value(String label, String? unit) =>
        (label: label, unit: unit, width: _valueWidth, isNumeric: true);
    return SeasonTable(
      columns: [
        (
          label: l10n.statsColumnYearCaps,
          unit: null,
          width: null,
          isNumeric: false,
        ),
        value(l10n.statsColumnRacesCaps, null),
        value(l10n.statsColumnTimeCaps, l10n.statsUnitHours),
        value(l10n.statsColumnDistanceCaps, l10n.tableUnitKilometers),
        value(l10n.statsColumnAverageSpeedCaps, l10n.tableUnitKnots),
        value(l10n.tableColumnClassCaps, l10n.statsUnitPodium),
        value(l10n.tableColumnOverallCaps, l10n.statsUnitPodium),
        value(l10n.tableColumnMonohullCaps, l10n.statsUnitPodium),
      ],
      rows: [for (final year in years) _row(year)],
    );
  }

  List<String> _row(SeasonYear year) {
    final volume = year.totals.volume;
    final placings = year.totals.placings;
    final time = volume.timeOnWater;
    final distance = volume.distanceMeters;
    final avgSpeed = year.totals.conditions.avgSpeedMps;
    return [
      '${year.year}',
      '${volume.raceCount}',
      if (time == null) missingValueLabel else formatSeasonHours(time),
      if (distance == null)
        missingValueLabel
      else
        formatTableKilometers(distance),
      if (avgSpeed == null) missingValueLabel else formatTableKnots(avgSpeed),
      '${placings.classPlacings.podiums}',
      '${placings.overallPlacings.podiums}',
      '${placings.monohullPlacings.podiums}',
    ];
  }
}
