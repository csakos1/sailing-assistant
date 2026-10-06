import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/polar/polar_providers.dart';
import 'package:foretack_web/polar/widgets/polar_loading.dart';
import 'package:foretack_web/polar/widgets/polar_quiet_note.dart';
import 'package:foretack_web/polar/widgets/polar_table.dart';
import 'package:foretack_web/polar/widgets/polar_table_line.dart';
import 'package:foretack_web/season_stats/widgets/season_section_heading.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az „Összes év" nézet polár-szakasza (ADR 0049 Addendum 5 W1; 16b).
///
/// Soronként egy szezon, csökkenő sorrendben, az időre súlyozott
/// értékekkel; rang nincs. Egy sorra kattintva az évsáv arra az évre
/// vált, mint az éremtáblán. Lábjegyzet itt nincs, az egy év nézetében
/// áll.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class PolarYearsSection extends ConsumerWidget {
  /// Szakasz [number] sorszámmal.
  const PolarYearsSection({
    required this.number,
    required this.onYearSelected,
    super.key,
  });

  /// A szakasz sorszáma.
  final int number;

  /// Egy évsorra kattintás.
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    Widget section(Widget body, {String? trailing}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeasonSectionHeading(
          number: number,
          title: l10n.polarYearsSectionCaps,
          trailing: trailing,
        ),
        body,
      ],
    );

    return ref
        .watch(polarSeasonsProvider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () => section(const PolarLoading()),
          error: (error, _) => section(
            isPolarUnavailable(error)
                ? PolarQuietNote(text: l10n.polarUnavailable)
                : PolarQuietNote(
                    text: l10n.polarLoadError,
                    onRetry: () => ref.invalidate(polarSeasonsProvider),
                  ),
          ),
          data: (seasons) => seasons.isEmpty
              ? const SizedBox.shrink()
              : section(
                  PolarTable(
                    isYearTable: true,
                    lines: [
                      for (final season in _newestFirst(seasons))
                        _yearLine(l10n, season),
                    ],
                  ),
                  trailing: l10n.polarYearsTrailing(_raceCount(seasons)),
                ),
        );
  }

  PolarTableLine _yearLine(WebLocalizations l10n, SeasonPolarSummary season) =>
      PolarTableLine(
        kind: PolarLineKind.year,
        lead: '${season.year}',
        title: '${season.raceCount}',
        titleSuffix: l10n.polarYearRacesSuffix,
        stats: season.timeWeighted,
        onTap: () => onYearSelected(season.year),
      );

  // Az évsáv is csökkenő sorrendű (ADR 0048 Addendum 7 N1); a szerver
  // sorrendjére nem építünk.
  static List<SeasonPolarSummary> _newestFirst(
    List<SeasonPolarSummary> seasons,
  ) => [...seasons]..sort((a, b) => b.year.compareTo(a.year));

  static int _raceCount(List<SeasonPolarSummary> seasons) =>
      seasons.fold(0, (sum, season) => sum + season.raceCount);
}
