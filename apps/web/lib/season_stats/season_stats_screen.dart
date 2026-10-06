import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/app/web_scroll_column.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/race_log/widgets/log_empty_message.dart';
import 'package:foretack_web/race_log/widgets/log_load_error.dart';
import 'package:foretack_web/race_log/widgets/log_period_band.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/season_stats.dart';
import 'package:foretack_web/season_stats/season_stats_provider.dart';
import 'package:foretack_web/season_stats/widgets/medal_breakdown_section.dart';
import 'package:foretack_web/season_stats/widgets/medal_table.dart';
import 'package:foretack_web/season_stats/widgets/season_overview_section.dart';
import 'package:foretack_web/season_stats/widgets/season_section_heading.dart';
import 'package:foretack_web/season_stats/widgets/track_records_section.dart';
import 'package:foretack_web/season_stats/widgets/wind_band_section.dart';

/// A Statisztika-képernyő (ADR 0049 D2–D4, Addendum 2).
///
/// A napló AppBarjából nyílik. Fent a napló évsávja és csíkja; alatta egy
/// évnél az évad, az osztály- és az abszolút helyezések, a pálya és a
/// szélsávok (R2), „Összes év" nézetben az éremtábla, a pálya és a
/// szélsávok (R3). Az időszak a naplóval közös.
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

class _SeasonStatsBody extends ConsumerWidget {
  const _SeasonStatsBody({required this.stats});

  final SeasonStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final totals = stats.totals;
    final volume = totals.volume;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogPeriodBand(view: stats.view),
        // A csík fix a görgetett tartalom fölött, mint a naplón (L1).
        WebColumn(
          child: RaceLogStatsStrip(
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
        ),
        Expanded(
          child: WebScrollColumn(
            bottomPadding: 56,
            children: stats.view.isAllYears
                ? _allYearsSections(l10n, ref)
                : _yearSections(l10n),
          ),
        ),
      ],
    );
  }

  // Egy év (R2): évad, osztály, abszolút, pálya, szél.
  List<Widget> _yearSections(WebLocalizations l10n) {
    final totals = stats.totals;
    final raceCount = totals.volume.raceCount;
    return [
      SeasonSectionHeading(number: 1, title: l10n.statsSeasonCaps),
      SeasonOverviewSection(placings: totals.placings, raceCount: raceCount),
      SeasonSectionHeading(number: 2, title: l10n.statsClassCaps),
      MedalBreakdownSection(
        tally: totals.placings.classPlacings,
        raceCount: raceCount,
      ),
      SeasonSectionHeading(number: 3, title: l10n.statsOverallCaps),
      MedalBreakdownSection(
        tally: totals.placings.overallPlacings,
        raceCount: raceCount,
      ),
      SeasonSectionHeading(number: 4, title: l10n.statsTrackCaps),
      TrackRecordsSection(
        conditions: totals.conditions,
        formatDay: formatMonthDay,
      ),
      SeasonSectionHeading(number: 5, title: l10n.statsWindBandsCaps),
      WindBandSection(conditions: totals.conditions),
    ];
  }

  // Minden év (R3): éremtábla, pálya, szél.
  List<Widget> _allYearsSections(WebLocalizations l10n, WidgetRef ref) {
    final totals = stats.totals;
    return [
      SeasonSectionHeading(number: 1, title: l10n.statsMedalTableCaps),
      MedalTable(
        years: stats.years,
        totals: totals,
        onYearSelected: (year) =>
            ref.read(logPeriodProvider.notifier).chooseYear(year),
      ),
      SeasonSectionHeading(number: 2, title: l10n.statsTrackCaps),
      TrackRecordsSection(
        conditions: totals.conditions,
        formatDay: formatFullDay,
      ),
      SeasonSectionHeading(number: 3, title: l10n.statsWindBandsCaps),
      WindBandSection(conditions: totals.conditions),
    ];
  }
}
