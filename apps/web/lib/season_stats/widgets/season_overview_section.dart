import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/season_placings.dart';
import 'package:foretack_web/season_stats/widgets/sail_mark.dart';

/// Az AZ ÉVAD szakasz törzse: három nagy szám és a versenyek vitorla-sora
/// (ADR 0049 Addendum 2 R2).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonOverviewSection extends StatelessWidget {
  /// Az évad a [placings] helyezésekből, a [raceCount] versenyhez mérve.
  const SeasonOverviewSection({
    required this.placings,
    required this.raceCount,
    super.key,
  });

  /// Az időszak helyezései.
  final SeasonPlacings placings;

  /// A megjelenített versenyek száma.
  final int raceCount;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final divider = SizedBox(
      width: 1,
      child: ColoredBox(color: scheme.outlineVariant),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BigNumber(
                  value: '${placings.podiumRaceCount}',
                  label: l10n.statsPodiumRacesCaps,
                  isLeading: true,
                ),
                divider,
                _BigNumber(
                  value: formatPercent(placings.podiumRaceCount, raceCount),
                  label: l10n.statsPodiumRateCaps,
                  color: scheme.primary,
                ),
                divider,
                _BigNumber(
                  value: '${placings.podiumPlacings}',
                  label: l10n.statsPodiumPlacingsCaps,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 5,
            runSpacing: 6,
            children: [
              for (final medal in placings.raceMedals)
                SailMark(medal: medal, width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.label,
    this.color,
    this.isLeading = false,
  });

  final String value;
  final String label;
  final Color? color;

  // Az első szám a szakaszcímmel egy vonalban áll, betét nélkül.
  final bool isLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: isLeading ? 0 : 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: numeralMediumStyle.copyWith(
                color: color ?? theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: sectionLabelStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
