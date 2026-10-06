import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';
import 'package:foretack_web/season_stats/season_conditions.dart';
import 'package:foretack_web/season_stats/season_record.dart';

// Egy pálya-mutató: felirat, a formázott érték (`null`: nincs adat), a
// mértékegység és a rekord versenye.
typedef _TrackTile = ({
  String label,
  String? value,
  String unit,
  SeasonRecord? record,
});

/// Az A PÁLYÁN szakasz törzse: hat mutató két sorban (ADR 0049 Addendum
/// 2 R2, R5).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class TrackRecordsSection extends StatelessWidget {
  /// A [conditions] mutatói; a verseny napját a [formatDay] írja ki.
  const TrackRecordsSection({
    required this.conditions,
    required this.formatDay,
    super.key,
  });

  /// Az időszak pálya-mutatói.
  final SeasonConditions conditions;

  /// A rekord napjának alakja: egy évnél `06.13.`, minden évre a teljes
  /// dátum.
  final String Function(DateTime day) formatDay;

  @override
  Widget build(BuildContext context) {
    final tiles = _tilesOf(WebLocalizations.of(context)!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
      child: Column(
        children: [
          for (var start = 0; start < tiles.length; start += 3)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, tile) in tiles.skip(start).take(3).indexed)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 24),
                        child: _TileView(tile: tile, formatDay: formatDay),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<_TrackTile> _tilesOf(WebLocalizations l10n) {
    final km = l10n.tableUnitKilometers;
    final kn = l10n.tableUnitKnots;
    final avgSpeed = conditions.avgSpeedMps;
    final windPoints = conditions.prevailingWindPoints;
    return [
      _recordTile(
        l10n.statsLongestRaceCaps,
        conditions.longestRace,
        km,
        formatTableKilometers,
      ),
      (
        label: l10n.statsAverageSpeedCaps,
        value: avgSpeed == null ? null : formatTableKnots(avgSpeed),
        unit: kn,
        record: null,
      ),
      _recordTile(
        l10n.statsFastestAverageCaps,
        conditions.fastestAverageRace,
        kn,
        formatTableKnots,
      ),
      _recordTile(
        l10n.statsTopSpeedCaps,
        conditions.fastestRace,
        kn,
        formatTableKnots,
      ),
      _recordTile(
        l10n.statsStrongestWindCaps,
        conditions.windiestRace,
        kn,
        formatTableKnots,
      ),
      (
        label: l10n.statsPrevailingWindCaps,
        value: windPoints.isEmpty
            ? null
            : windPoints.map(compassPointLabel).join(' / '),
        unit: '',
        record: null,
      ),
    ];
  }

  static _TrackTile _recordTile(
    String label,
    SeasonRecord? record,
    String unit,
    String Function(double value) format,
  ) => (
    label: label,
    value: record == null ? null : format(record.value),
    unit: unit,
    record: record,
  );
}

class _TileView extends StatelessWidget {
  const _TileView({required this.tile, required this.formatDay});

  final _TrackTile tile;
  final String Function(DateTime day) formatDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tones = theme.extension<TextTones>()!;
    final value = tile.value;
    final record = tile.record;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tile.label,
              style: sectionLabelStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value ?? missingValueLabel,
                  style: numeralSmallStyle.copyWith(
                    color: value == null ? tones.low : scheme.onSurface,
                  ),
                ),
                // Hiányzó értéknél nincs mértékegység (ADR 0044 D29).
                if (value != null && tile.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    tile.unit,
                    style: supportTextStyle.copyWith(
                      fontSize: 12,
                      color: tones.low,
                    ),
                  ),
                ],
              ],
            ),
            if (record != null) ...[
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: record.raceName,
                  style: supportTextStyle.copyWith(color: scheme.onSurface),
                  children: [
                    TextSpan(
                      text: ' · ${formatDay(record.day)}',
                      style: supportTextStyle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
