import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/season_totals.dart';
import 'package:foretack_web/season_stats/widgets/season_quiet_note.dart';

/// A MENNYISÉG szakasz: a stat-csík és alatta a halk sorok (ADR 0049 D3
/// 1., Addendum 1 P1, P4).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonVolumeSection extends StatelessWidget {
  /// A [totals] mennyiségi szakasza.
  const SeasonVolumeSection({required this.totals, super.key});

  /// A megjelenített időszak összesítése.
  final SeasonTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final volume = totals.volume;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RaceLogStatsStrip(
          cells: [
            (
              label: l10n.statsStatRacesCaps,
              measured: (value: '${volume.raceCount}', unit: ''),
            ),
            (
              label: l10n.logStatTimeCaps,
              measured: measureHours(volume.timeOnWater),
            ),
            (
              label: l10n.logStatDistanceCaps,
              measured: measureDistance(volume.distanceMeters),
            ),
          ],
        ),
        SeasonQuietNote(
          text: l10n.statsOriginSplit(
            volume.telemetryRaceCount,
            volume.manualRaceCount,
          ),
        ),
        if (volume.racesWithoutTime > 0)
          SeasonQuietNote(
            text: l10n.statsRacesWithoutTime(volume.racesWithoutTime),
          ),
        if (totals.hasApproximateValues)
          SeasonQuietNote(text: l10n.statsApproximate),
      ],
    );
  }
}
