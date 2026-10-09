import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/polar/polar_formatters.dart';
import 'package:foretack_web/polar/polar_providers.dart';
import 'package:foretack_web/polar/widgets/polar_loading.dart';
import 'package:foretack_web/polar/widgets/polar_quiet_note.dart';
import 'package:foretack_web/polar/widgets/polar_table.dart';
import 'package:foretack_web/polar/widgets/polar_table_line.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';
import 'package:foretack_web/season_stats/widgets/season_section_heading.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Az egy év nézet polár-szakasza (ADR 0049 Addendum 5 W1, W2; 16a).
///
/// Saját szakaszcímmel jön, mert a címsor jobb oldala a betöltött
/// versenyszámot mondja, és verseny nélküli évben a szakasz elmarad. A
/// többi szakasz nem vár rá: betöltés alatt csak itt forog a jelző.
///
/// A `WebLocalizations.of(context)!` és a `TextTones` biztonságos: a
/// `MaterialApp` és a `foretackTheme` regisztrálja őket.
class PolarSeasonSection extends ConsumerWidget {
  /// A [year] polár-szakasza [number] sorszámmal.
  const PolarSeasonSection({
    required this.number,
    required this.year,
    required this.onRaceSelected,
    super.key,
  });

  /// A szakasz sorszáma.
  final int number;

  /// A szezon éve.
  final int year;

  /// Egy verseny-sorra kattintás: a részletező megnyitása.
  final void Function(RacePolarRow row) onRaceSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    Widget section(Widget body, {String? trailing}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeasonSectionHeading(
          number: number,
          title: l10n.polarSeasonSectionCaps,
          trailing: trailing,
        ),
        body,
      ],
    );

    return ref
        .watch(seasonPolarProvider(year))
        .when(
          // Az ÚJRA után a jelző látsszon, ne a régi hiba.
          skipLoadingOnRefresh: false,
          loading: () => section(const PolarLoading()),
          error: (error, _) => section(
            isPolarUnavailable(error)
                ? PolarQuietNote(text: l10n.polarUnavailable)
                : PolarQuietNote(
                    text: l10n.polarLoadError,
                    onRetry: () => ref.invalidate(seasonPolarProvider(year)),
                  ),
          ),
          data: (table) => table.rows.isEmpty
              ? const SizedBox.shrink()
              : section(
                  _SeasonPolarBody(
                    table: table,
                    onRaceSelected: onRaceSelected,
                  ),
                  trailing: l10n.polarSeasonTrailing(table.rows.length),
                ),
        );
  }
}

class _SeasonPolarBody extends StatelessWidget {
  const _SeasonPolarBody({required this.table, required this.onRaceSelected});

  final SeasonPolarTable table;
  final void Function(RacePolarRow row) onRaceSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = WebLocalizations.of(context)!;
    final theme = Theme.of(context);
    final low = theme.extension<TextTones>()!.low;
    final raceAverage = table.raceAverage;
    final timeWeighted = table.timeWeighted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Egy sor a szakasz tetején, nem cellánként (16d-2).
        if (table.isStale) PolarQuietNote(text: l10n.polarStale),
        PolarTable(
          lines: [for (final row in table.rows) _raceLine(l10n, row)],
          totals: [
            if (raceAverage != null)
              PolarTableLine(
                kind: PolarLineKind.raceAverage,
                title: l10n.polarRaceAverage,
                stats: raceAverage,
              ),
            if (timeWeighted != null)
              PolarTableLine(
                kind: PolarLineKind.timeWeighted,
                title: l10n.polarTimeWeighted,
                stats: timeWeighted,
              ),
          ],
        ),
        if (timeWeighted != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WebLayout.columnInset,
              2,
              WebLayout.columnInset,
              0,
            ),
            child: Text(
              l10n.polarMeasuredHours(
                formatMeasuredHours(timeWeighted.measuredSeconds),
              ),
              style: supportTextStyle.copyWith(color: low),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: WebLayout.textMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                WebLayout.columnInset,
                16,
                WebLayout.columnInset,
                0,
              ),
              child: Text(
                l10n.polarFootnote,
                style: supportTextStyle.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PolarTableLine _raceLine(WebLocalizations l10n, RacePolarRow row) {
    // Kevés adat: a szerződés 60 mp alatt nem ad mutatót (W2).
    final isFewData =
        row.stats == null && row.cacheState != PolarCacheState.missing;
    final day = row.day;
    return PolarTableLine(
      kind: PolarLineKind.race,
      lead: row.rank?.toString(),
      date: formatMonthDay(DateTime(day.year, day.month, day.day)),
      title: row.name,
      subtitle: _subtitle(l10n, row, isFewData: isFewData),
      isApproximate: row.isApproximate,
      isMuted: isFewData,
      stats: row.stats,
      onTap: () => onRaceSelected(row),
    );
  }

  // A név alatti sor: a hiányzó cache-sor és a kevés adat a menetidő
  // helyén áll (W2).
  static String? _subtitle(
    WebLocalizations l10n,
    RacePolarRow row, {
    required bool isFewData,
  }) {
    if (row.cacheState == PolarCacheState.missing) return l10n.polarNotComputed;
    if (isFewData) return l10n.polarFewData;
    final elapsed = row.elapsed;
    return elapsed == null ? null : formatHoursMinutes(elapsed);
  }
}
