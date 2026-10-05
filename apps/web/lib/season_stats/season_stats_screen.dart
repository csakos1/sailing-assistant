import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/app/web_scroll_column.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/detail_section_label.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/race_log/widgets/log_empty_message.dart';
import 'package:foretack_web/race_log/widgets/log_load_error.dart';
import 'package:foretack_web/race_log/widgets/log_period_band.dart';
import 'package:foretack_web/season_stats/season_stats.dart';
import 'package:foretack_web/season_stats/season_stats_provider.dart';
import 'package:foretack_web/season_stats/widgets/season_conditions_section.dart';
import 'package:foretack_web/season_stats/widgets/season_placings_table.dart';
import 'package:foretack_web/season_stats/widgets/season_volume_section.dart';
import 'package:foretack_web/season_stats/widgets/season_years_table.dart';

/// A Statisztika-képernyő (ADR 0049 D2–D4, Addendum 1 P1).
///
/// A napló AppBarjából nyílik. Fentről lefelé: a napló évsávja, a
/// MENNYISÉG csík, a HELYEZÉSEK táblája, a SEBESSÉG ÉS SZÉL szakasz, és
/// „Összes év" nézetben az ÉVEK táblája. Az időszak a naplóval közös.
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class SeasonStatsScreen extends ConsumerWidget {
  /// A Statisztika-képernyő; mindent providerből olvas.
  const SeasonStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final statsState = ref.watch(seasonStatsProvider);
    return Scaffold(
      appBar: WebAppBar(title: l10n.statsTitle, showBack: true),
      body: statsState.when(
        // Az ÚJRA után a folyamatjelző látsszon, ne a régi hiba.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => LogLoadError(
          onRetry: () => ref.invalidate(raceSummariesProvider),
        ),
        data: (stats) => stats.view.isEmpty
            ? const LogEmptyMessage()
            : _SeasonStatsBody(stats: stats),
      ),
    );
  }
}

class _SeasonStatsBody extends StatelessWidget {
  const _SeasonStatsBody({required this.stats});

  final SeasonStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final totals = stats.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogPeriodBand(view: stats.view),
        Expanded(
          child: WebScrollColumn(
            bottomPadding: 56,
            children: [
              SeasonVolumeSection(totals: totals),
              DetailSectionLabel(text: l10n.statsPlacingsCaps),
              SeasonPlacingsTable(
                placings: totals.placings,
                raceCount: totals.volume.raceCount,
              ),
              SeasonConditionsSection(conditions: totals.conditions),
              if (stats.years.isNotEmpty) ...[
                DetailSectionLabel(text: l10n.statsYearsCaps),
                SeasonYearsTable(years: stats.years),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
