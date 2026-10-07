import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/file_download_provider.dart';
import 'package:foretack_web/app/web_app_bar.dart';
import 'package:foretack_web/app/web_column.dart';
import 'package:foretack_web/app/web_layout.dart';
import 'package:foretack_web/app/web_scroll_column.dart';
import 'package:foretack_web/auth/account_menu.dart';
import 'package:foretack_web/auth/session_provider.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_detail/race_detail_screen.dart';
import 'package:foretack_web/race_edit/manual_race_editor_screen.dart';
import 'package:foretack_web/race_import/import_dialog.dart';
import 'package:foretack_web/race_log/log_view_mode.dart';
import 'package:foretack_web/race_log/log_view_mode_provider.dart';
import 'package:foretack_web/race_log/race_log_providers.dart';
import 'package:foretack_web/race_log/race_log_view.dart';
import 'package:foretack_web/race_log/table/race_table.dart';
import 'package:foretack_web/race_log/table/race_table_items.dart';
import 'package:foretack_web/race_log/table/race_table_sort_provider.dart';
import 'package:foretack_web/race_log/widgets/log_app_bar_icon_button.dart';
import 'package:foretack_web/race_log/widgets/log_empty_message.dart';
import 'package:foretack_web/race_log/widgets/log_load_error.dart';
import 'package:foretack_web/race_log/widgets/log_period_band.dart';
import 'package:foretack_web/race_log/widgets/log_view_toggle.dart';
import 'package:foretack_web/season_stats/season_stats_screen.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A webes Versenynapló, Lista és Táblázat nézettel (ADR 0047 D8, ADR
/// 0048 Addendum 4 K3–K4, K25–K32).
///
/// Fentről lefelé: az AppBar, a 7c évsáv, a phone stat-csíkja, majd a
/// hónapokra bontott lista a phone sorával (nap és név), vagy a táblázat.
/// Az „összes év" választásnál a hónapok fölé évfejléc kerül (14w).
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
    final isLogEmpty = logState.valueOrNull?.isEmpty ?? false;
    // A módosítás belépési pontjai csak a tulajdonosé (ADR 0051 Addendum 7
    // P7); a szerver a `crew` kéréseit amúgy is elutasítja.
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: WebAppBar(
        title: l10n.logTitle,
        actions: [
          // A váltó minden állapotban látszik, és megtartja az állását (G1).
          LogViewToggle(
            mode: ref.watch(logViewModeProvider),
            onChanged: (mode) =>
                ref.read(logViewModeProvider.notifier).mode = mode,
          ),
          const SizedBox(width: 8),
          LogAppBarIconButton(
            tooltip: l10n.logStatistics,
            icon: Icons.bar_chart,
            onPressed: () => unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SeasonStatsScreen(),
                ),
              ),
            ),
          ),
          if (isOwner) ...[
            // A böngésző tölti le; a hibát a letöltés-sávja jelzi (ADR 0050
            // Addendum 3 G2).
            LogAppBarIconButton(
              tooltip: l10n.logExport,
              icon: Icons.download_outlined,
              onPressed: () => ref.read(fileDownloadProvider)(exportPath),
            ),
            const SizedBox(width: 8),
            // Keret nélküli gomb: a váltótól és a Feltöltéstől is eltér, de
            // velük egy magas (Addendum 5 L6).
            TextButton.icon(
              onPressed: () => unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManualRaceEditorScreen(),
                  ),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.logNewRace),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ).merge(_appBarControlStyle),
            ),
            const SizedBox(width: 8),
            _UploadButton(isLogEmpty: isLogEmpty),
          ],
          const _AppBarDivider(),
          // A jobb szélső elem az oszlop betétjén áll (G1).
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: AccountMenu(),
          ),
        ],
      ),
      body: logState.when(
        // Az ÚJRA után a folyamatjelző látsszon, ne a régi hiba.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => LogLoadError(
          onRetry: () => ref.invalidate(raceSummariesProvider),
        ),
        data: (view) =>
            view.isEmpty ? const LogEmptyMessage() : _RaceLogBody(view: view),
      ),
    );
  }
}

// Az AppBar vezérlőinek közös mérete és betűje (Addendum 5 L6). A weben
// a gombok alapból kompakt sűrűséget kapnak (32 px), ezért a magasság és a
// sűrűség itt rögzített, hogy a váltóval egy magasak legyenek.
final ButtonStyle _appBarControlStyle = ButtonStyle(
  minimumSize: const WidgetStatePropertyAll(
    Size(0, WebLayout.appBarControlHeight),
  ),
  fixedSize: const WidgetStatePropertyAll(
    Size.fromHeight(WebLayout.appBarControlHeight),
  ),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 14),
  ),
  visualDensity: VisualDensity.standard,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
  textStyle: WidgetStatePropertyAll(
    supportTextStyle.copyWith(fontWeight: FontWeight.w600),
  ),
);

/// Függőleges elválasztó a vezérlők és a név-menü között (ADR 0051
/// Addendum 1 H4).
class _AppBarDivider extends StatelessWidget {
  const _AppBarDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      width: 1,
      height: 24,
      child: ColoredBox(color: Theme.of(context).colorScheme.outline),
    ),
  );
}

/// A Feltöltés gomb (ADR 0048 Addendum 4 K23). Üres naplóban kitöltött,
/// mert ott ez a fő akció (13b).
class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.isLogEmpty});

  final bool isLogEmpty;

  @override
  Widget build(BuildContext context) {
    final label = Text(WebLocalizations.of(context)!.logUpload);
    const icon = Icon(Icons.upload, size: 18);
    void open() => unawaited(showImportDialog(context));
    if (isLogEmpty) {
      return FilledButton.icon(
        onPressed: open,
        icon: icon,
        label: label,
        style: _appBarControlStyle,
      );
    }
    // A fő adatforrás: teal keret és felirat, a váltó szürke keretétől
    // eltérően (Addendum 5 L6).
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton.icon(
      onPressed: open,
      icon: icon,
      label: label,
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary),
      ).merge(_appBarControlStyle),
    );
  }
}

/// A részletező megnyitása (ADR 0048 Addendum 4 K7), `MaterialPageRoute`-tal.
void _openDetail(BuildContext context, RaceSummary summary) => unawaited(
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          RaceDetailScreen(raceId: summary.id, raceName: summary.name),
    ),
  ),
);

class _RaceLogBody extends ConsumerWidget {
  const _RaceLogBody({required this.view});

  final RaceLogView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = WebLocalizations.of(context)!;
    final totals = view.totals;
    final mode = ref.watch(logViewModeProvider);
    final sort = ref.watch(raceTableSortProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogPeriodBand(view: view),
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
          child: switch (mode) {
            LogViewMode.list => WebScrollColumn(
              bottomPadding: 56,
              children: _rows(context, l10n),
            ),
            LogViewMode.table => RaceTable(
              items: raceTableItemsOf(view, sort),
              sort: sort,
              onSortTap: ref.read(raceTableSortProvider.notifier).tapColumn,
              onOpen: (summary) => _openDetail(context, summary),
            ),
          },
        ),
      ],
    );
  }

  List<Widget> _rows(BuildContext context, WebLocalizations l10n) => [
    for (final year in view.shownYears) ...[
      if (view.isAllYears) _YearHeading(year: year.year),
      for (final month in year.months) ...[
        RaceLogMonthHeader(
          monthLabel: l10n.logMonth(DateTime(year.year, month.month)),
          countLabel: l10n.logRaceCountCaps(month.entries.length),
        ),
        for (final entry in month.entries)
          RaceLogRow.entry(
            day: entry.day.day,
            name: entry.summary.name,
            onTap: () => _openDetail(context, entry.summary),
          ),
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
