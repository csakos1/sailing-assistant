import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_section_label.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_record.dart';
import 'package:foretack_web/season_stats/widgets/season_quiet_note.dart';
import 'package:foretack_web/season_stats/widgets/season_table.dart';
import 'package:foretack_web/season_stats/widgets/wind_band_bars.dart';
import 'package:foretack_web/season_stats/wind_band.dart';

/// A SEBESSÉG ÉS SZÉL szakasz: a rekord-tábla és a szélsávok (ADR 0049
/// D3 3., Addendum 1 P1, P3).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonConditionsSection extends StatelessWidget {
  /// A [conditions] szakasza.
  const SeasonConditionsSection({required this.conditions, super.key});

  /// A megjelenített időszak sebesség- és szél-mutatói.
  final SeasonConditions conditions;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final avgSpeed = conditions.avgSpeedMps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailSectionLabel(text: l10n.statsConditionsCaps),
        SeasonTable(
          columns: [
            (label: '', unit: null, width: null, isNumeric: false),
            (
              label: l10n.statsColumnValueCaps,
              unit: l10n.tableUnitKnots,
              width: 88,
              isNumeric: true,
            ),
            (
              label: l10n.statsColumnRaceCaps,
              unit: null,
              width: 280,
              isNumeric: false,
            ),
            (
              label: l10n.statsColumnDateCaps,
              unit: null,
              width: 104,
              isNumeric: true,
            ),
          ],
          rows: [
            [
              l10n.statsRowAvgSpeed,
              if (avgSpeed == null)
                missingValueLabel
              else
                formatTableKnots(avgSpeed),
              '',
              '',
            ],
            _recordRow(l10n.statsRowMaxSpeed, conditions.fastestRace),
            _recordRow(l10n.statsRowMaxWind, conditions.windiestRace),
          ],
        ),
        DetailSectionLabel(text: l10n.statsWindBandsCaps),
        WindBandBars(
          bars: [
            for (final band in WindBand.values)
              (
                label: _bandLabel(l10n, band),
                count: conditions.windBandCounts[band] ?? 0,
              ),
          ],
        ),
        if (conditions.racesWithoutWind > 0)
          SeasonQuietNote(
            text: l10n.statsRacesWithoutWind(conditions.racesWithoutWind),
          ),
      ],
    );
  }

  List<String> _recordRow(String label, SeasonRecord? record) =>
      switch (record) {
        null => [label, missingValueLabel, '', ''],
        (:final valueMps, :final raceName, :final day) => [
          label,
          formatTableKnots(valueMps),
          raceName,
          formatTableDate(day),
        ],
      };

  String _bandLabel(WebLocalizations l10n, WindBand band) =>
      switch ((band.lowerKnots, band.upperKnots)) {
        (null, final int high) => l10n.statsWindBandBelow(high),
        (final int low, null) => l10n.statsWindBandAbove(low),
        (final int low, final int high) => l10n.statsWindBandRange(low, high),
        // Határ nélküli sáv nincs; az ág csak a kimerítő mintához kell.
        (null, null) => '',
      };
}
