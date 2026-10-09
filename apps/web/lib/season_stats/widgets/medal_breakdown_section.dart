import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/placing_tally.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/widgets/sail_mark.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az OSZTÁLYBAN és az ABSZOLÚT szakasz törzse: I., II., III. hely
/// darabszámmal, vitorlákkal és aránnyal, alatta a dobogós helyezések és
/// a dobogón kívüli helyezések (ADR 0049 Addendum 2 R2, R5).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class MedalBreakdownSection extends StatelessWidget {
  /// A [tally] kategória, a [raceCount] versenyhez mérve.
  const MedalBreakdownSection({
    required this.tally,
    required this.raceCount,
    super.key,
  });

  /// A kategória helyezései.
  final PlacingTally tally;

  /// A megjelenített versenyek száma.
  final int raceCount;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final tones = Theme.of(context).extension<TextTones>()!;
    final offPodium = tally.offPodium;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WebLayout.columnInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final medal in Medal.values)
            _MedalRow(
              medal: medal,
              label: _placeLabel(l10n, medal),
              count: tally.countOf(medal),
              raceCount: raceCount,
            ),
          const SizedBox(height: 8),
          SizedBox(height: 1, child: ColoredBox(color: scheme.outlineVariant)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${tally.podiums}',
                style: numeralSmallStyle.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.statsPodiumPlacingsCaps,
                style: sectionLabelStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (offPodium.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: '${l10n.statsOffPodium} ',
                style: supportTextStyle.copyWith(color: tones.low),
                children: [
                  TextSpan(
                    text: offPodium.map(_placingLabel).join(' · '),
                    style: numeralMicroStyle.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _placeLabel(WebLocalizations l10n, Medal medal) =>
      switch (medal) {
        Medal.gold => l10n.statsFirstPlaceCaps,
        Medal.silver => l10n.statsSecondPlaceCaps,
        Medal.bronze => l10n.statsThirdPlaceCaps,
      };

  static String _placingLabel(Placing placing) => switch (placing) {
    FinishPlace(:final place) => '$place.',
    Dnf() => 'DNF',
    Dsq() => 'DSQ',
  };
}

class _MedalRow extends StatelessWidget {
  const _MedalRow({
    required this.medal,
    required this.label,
    required this.count,
    required this.raceCount,
  });

  final Medal medal;
  final String label;
  final int count;
  final int raceCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tones = theme.extension<TextTones>()!;
    final color = medalColorOf(theme.extension<MedalColors>()!, medal);
    final ofStarts = WebLocalizations.of(context)!.statsOfStarts(raceCount);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: sectionLabelStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$count',
              style: numeralSmallStyle.copyWith(
                fontSize: 28,
                color: count == 0 ? tones.low : color,
              ),
            ),
          ),
          Expanded(
            child: count == 0
                ? Text(
                    missingValueLabel,
                    style: numeralMicroStyle.copyWith(color: tones.low),
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var index = 0; index < count; index++)
                        SailMark(medal: medal, width: 10),
                    ],
                  ),
          ),
          Text.rich(
            TextSpan(
              text: formatPercent(count, raceCount),
              style: numeralMicroStyle.copyWith(color: scheme.onSurface),
              children: [
                TextSpan(
                  text: ' $ofStarts',
                  style: supportTextStyle.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
