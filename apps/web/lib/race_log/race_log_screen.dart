import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/race_log/race_log_view.dart';

/// A webes Versenynapló, Lista nézet (ADR 0047 D8, ADR 0048 Addendum 4
/// K3–K4).
///
/// Fentről lefelé: az AppBar, a 7c évsáv, a phone stat-csíkja, majd a
/// hónapokra bontott lista a phone sorával (nap és név). Az „összes év"
/// választásnál a hónapok fölé évfejléc kerül (14w).
///
/// A `WebLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceLogScreen extends ConsumerWidget {
  /// A napló képernyője; mindent providerből olvas.
  const RaceLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final logState = ref.watch(raceLogViewProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: WebLayout.appBarHeight,
        titleSpacing: 0,
        title: WebColumn(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WebLayout.columnInset,
            ),
            child: Text(l10n.logTitle, style: screenTitleStyle),
          ),
        ),
      ),
      body: logState.when(
        // Az ÚJRA után a folyamatjelző látsszon, ne a régi hiba.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(
          onRetry: () => ref.invalidate(raceSummariesProvider),
        ),
        data: (view) =>
            view.isEmpty ? const _EmptyLog() : _RaceLogBody(view: view),
      ),
    );
  }
}

class _RaceLogBody extends ConsumerWidget {
  const _RaceLogBody({required this.view});

  final RaceLogView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final totals = view.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A sáv teljes szélességű, a tartalma az oszlopban (E3).
        ColoredBox(
          color: scheme.surfaceContainer,
          child: WebColumn(
            child: RaceLogYearSelector(
              selectedLabel: _selectedLabel(l10n),
              options: [
                for (final year in view.availableYears)
                  if (year != view.selectedYear)
                    (
                      label: '$year',
                      onSelected: () =>
                          ref.read(logPeriodProvider.notifier).chooseYear(year),
                    ),
              ],
              allYearsOption: view.isAllYears
                  ? null
                  : (
                      label: l10n.logAllYearsCaps,
                      onSelected: () =>
                          ref.read(logPeriodProvider.notifier).chooseAllYears(),
                    ),
              countLabel: l10n.logRaceCountCaps(view.raceCount),
            ),
          ),
        ),
        WebColumn(
          child: RaceLogStatsStrip(
            cells: [
              (
                label: l10n.logStatTimeCaps,
                measured: measureHours(totals.timeOnWater),
              ),
              (
                label: l10n.logStatDistanceCaps,
                measured: measureDistance(totals.distanceMeters),
              ),
              (
                label: l10n.logStatRecordCaps,
                measured: measureKnots(totals.maxSpeedMps),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: WebLayout.columnMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 56),
                children: _rows(l10n),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _selectedLabel(WebLocalizations l10n) {
    final selected = view.selectedYear;
    if (selected != null) return '$selected';
    // Az évek csökkenő sorrendben jönnek: az utolsó a legkorábbi.
    final years = view.availableYears;
    return l10n.logYearRange(years.last, years.first);
  }

  // A sorra kattintás az S7b-ig nem nyit semmit: a részletező ott készül
  // el (K4).
  List<Widget> _rows(WebLocalizations l10n) => [
    for (final year in view.shownYears) ...[
      if (view.isAllYears) _YearHeading(year: year.year),
      for (final month in year.months) ...[
        RaceLogMonthHeader(
          monthLabel: l10n.logMonth(DateTime(year.year, month.month)),
          countLabel: l10n.logRaceCountCaps(month.entries.length),
        ),
        for (final entry in month.entries)
          RaceLogRow.entry(day: entry.day.day, name: entry.summary.name),
      ],
    ],
  ];
}

/// Évfejléc az „összes év" listájában (14w); a hónap-fejlécek fölött áll.
class _YearHeading extends StatelessWidget {
  const _YearHeading({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 32, 20, 0),
    child: Text(
      '$year',
      style: numeralSmallStyle.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WebLayout.columnInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.logLoadError,
              style: supportTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.logRetryCaps)),
          ],
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(WebLayout.columnInset),
      child: Text(
        WebLocalizations.of(context)!.logEmpty,
        style: supportTextStyle,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
