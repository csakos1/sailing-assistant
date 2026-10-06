import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/season_stats.dart';
import 'package:foretack_web/season_stats/season_totals.dart';
import 'package:foretack_web/season_stats/widgets/sail_mark.dart';

// Az oszlopok szélessége (15b); az év termése kapja a maradékot. Az
// érem-cellák fix rekeszek, hogy a számok évről évre egymás alatt álljanak.
const double _yearWidth = 76;
const double _startsWidth = 72;
const double _podiumWidth = 96;
const double _medalWidth = 44;
const double _groupGap = 12;

/// Az ÉREMTÁBLA ÉVENKÉNT szakasz törzse „Összes év" nézetben (ADR 0049
/// Addendum 2 R3, R5).
///
/// Egy évsorra kattintva az [onYearSelected] arra az évre vált.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class MedalTable extends StatelessWidget {
  /// Éremtábla a [years] soraival és a [totals] összesítő sorával.
  const MedalTable({
    required this.years,
    required this.totals,
    required this.onYearSelected,
    super.key,
  });

  /// Az évek, csökkenő sorrendben.
  final List<SeasonYear> years;

  /// A teljes időszak összesítése az „Össz." sorhoz.
  final SeasonTotals totals;

  /// Egy év kiválasztása az évsávon.
  final void Function(int year) onYearSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderRow(l10n: l10n),
        for (final (:year, totals: yearTotals) in years)
          InkWell(
            onTap: () => onYearSelected(year),
            hoverColor: scheme.surfaceContainer,
            child: _MedalRow(
              lead: Text(
                '$year',
                style: numeralSmallStyle.copyWith(color: scheme.onSurface),
              ),
              totals: yearTotals,
              line: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        _MedalRow(
          lead: Text(
            l10n.statsTotalRow,
            style: listItemTitleStyle.copyWith(color: scheme.onSurface),
          ),
          totals: totals,
          line: BorderSide.none,
          topLine: BorderSide(color: scheme.outline, width: 2),
          isTotal: true,
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.l10n});

  final WebLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = sectionLabelStyle.copyWith(
      color: Theme.of(context).extension<TextTones>()!.low,
    );
    Widget cell(String text, double width) => SizedBox(
      width: width,
      child: Text(text, style: style),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          WebLayout.columnInset,
          0,
          WebLayout.columnInset,
          10,
        ),
        child: Row(
          children: [
            cell(l10n.statsColumnYearCaps, _yearWidth),
            cell(l10n.statsColumnStartsCaps, _startsWidth),
            cell(l10n.statsColumnPodiumCaps, _podiumWidth),
            cell(l10n.statsClassCaps, _medalWidth * 3 + _groupGap),
            cell(l10n.statsOverallCaps, _medalWidth * 3 + _groupGap),
            Expanded(child: Text(l10n.statsColumnHarvestCaps, style: style)),
          ],
        ),
      ),
    );
  }
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({
    required this.lead,
    required this.totals,
    required this.line,
    this.topLine = BorderSide.none,
    this.isTotal = false,
  });

  final Widget lead;
  final SeasonTotals totals;
  final BorderSide line;
  final BorderSide topLine;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final placings = totals.placings;
    final raceCount = totals.volume.raceCount;
    final podiumRate = formatPercent(placings.podiumRaceCount, raceCount);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: topLine, bottom: line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WebLayout.columnInset,
          vertical: 14,
        ),
        child: Row(
          children: [
            SizedBox(width: _yearWidth, child: lead),
            SizedBox(
              width: _startsWidth,
              child: Text(
                '$raceCount',
                style: numeralMicroStyle.copyWith(color: scheme.onSurface),
              ),
            ),
            SizedBox(
              width: _podiumWidth,
              child: Text.rich(
                TextSpan(
                  text: '${placings.podiumRaceCount}',
                  style: numeralMicroStyle.copyWith(color: scheme.onSurface),
                  children: [
                    TextSpan(
                      text: '  $podiumRate',
                      style: numeralCaptionStyle.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _MedalCells(tally: placings.classPlacings),
            const SizedBox(width: _groupGap),
            _MedalCells(tally: placings.overallPlacings),
            const SizedBox(width: _groupGap),
            Expanded(
              child: isTotal
                  ? Text.rich(
                      TextSpan(
                        text: '${placings.podiumPlacings}',
                        style: numeralSmallStyle.copyWith(
                          color: scheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${l10n.statsHarvestTotal}',
                            style: supportTextStyle.copyWith(color: tones.low),
                          ),
                        ],
                      ),
                    )
                  : Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: [
                        for (final medal in placings.harvest)
                          SailMark(medal: medal, width: 8),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalCells extends StatelessWidget {
  const _MedalCells({required this.tally});

  final PlacingTally tally;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<MedalColors>()!;
    final low = theme.extension<TextTones>()!.low;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final medal in Medal.values)
          SizedBox(
            width: _medalWidth,
            child: switch (tally.countOf(medal)) {
              0 => Text(
                missingValueLabel,
                style: numeralMicroStyle.copyWith(color: low),
              ),
              final count => Row(
                children: [
                  SailMark(medal: medal, width: 8),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: numeralMicroStyle.copyWith(
                      color: medalColorOf(colors, medal),
                    ),
                  ),
                ],
              ),
            },
          ),
      ],
    );
  }
}
