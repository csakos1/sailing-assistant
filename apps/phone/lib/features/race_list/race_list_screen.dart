import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/engine/engine_debug_screen.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/widgets/list_action_bar.dart';
import 'package:phone/features/race_list/widgets/race_list_row.dart';
import 'package:phone/features/race_log/race_log_screen.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/crew_screen.dart';
import 'package:phone/features/web_access/presentation/qr_scan_screen.dart';
import 'package:phone/features/web_access/presentation/web_access_banners.dart';
import 'package:phone/features/web_access/presentation/web_access_menu.dart';
import 'package:phone/features/web_access/presentation/web_access_refresher.dart';
import 'package:phone/features/web_access/presentation/web_account_screen.dart';
import 'package:phone/features/web_access/presentation/web_login_snack_bar.dart';
import 'package:phone/features/web_access/presentation/web_sessions_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';

/// A versenyek listája — az app `home` képernyője (ADR 0044 D10–D18 +
/// Addendum 2).
///
/// A `raceListProvider` reaktív projekcióját mutatja (loading/error/data).
/// A fő lista státusz szerint particionál (ADR 0033): csak a folyamatban
/// lévő (elöl) és a nem indult versenyek látszanak, teljes szélességű
/// hairline-sorokban; a befejezettek az alsó akció-sáv bal gombja mögötti
/// modalba kerülnek. Ha nincs befejezett verseny, a gomb **letiltva** marad
/// és nem tűnik el, különben a sáv felezése ugrálna.
///
/// Az AppBar első gombja a webes QR-beolvasó (ADR 0051 Addendum 1 H1),
/// utána a Fázis 3 debug raw-viewer; debug-buildben mellette a
/// háttér-engine verifikáló képernyője, a végén a webes hozzáférés ⋮
/// menüje (ADR 0051 Addendum 10 Z6). A törzset a webes állapot frissítője
/// öleli, a lista fölött a szalagokkal (Addendum 9 X3, Addendum 10 Z5,
/// Z7). Az
/// `AppLocalizations.of(context)!` biztonságos: a `MaterialApp`
/// regisztrálja a delegátorokat.
class RaceListScreen extends ConsumerWidget {
  const RaceListScreen({super.key});

  void _openSetup(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RaceSetupScreen()),
      ),
    );
  }

  void _openDetail(BuildContext context, Race race) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => RaceDetailScreen(race: race)),
      ),
    );
  }

  /// A befejezett versenyek modalját nyitja; a kiválasztott versenyt a
  /// meglévő detail-útvonalon nyitja meg (a sheet a `Race`-szel popol). A
  /// fogantyú-csíkot a sheet maga rajzolja (nincs `showDragHandle`).
  Future<void> _openFinished(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RaceLogScreen()),
    );
  }

  void _openDebug(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RawNmeaViewerScreen()),
      ),
    );
  }

  // A webes QR-beolvasó (ADR 0051 Addendum 1 H1); sikeres belépés után a
  // főképernyő mutatja a snackbart (18d).
  Future<void> _openScanner(BuildContext context) async {
    final details = await QrScanScreen.open(context);
    if (details == null || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(webLoginSnackBar(context, details));
  }

  // A webes kezelőképernyők; visszatérve a szalag frissül (Z5), hogy egy
  // kiléptetett munkamenet gyanús jelzése vagy egy eldöntött kérelem
  // azonnal eltűnjön.
  Future<void> _openWebAccess(
    BuildContext context,
    WidgetRef ref,
    WebAccessMenuItem item,
  ) async {
    switch (item) {
      case WebAccessMenuItem.sessions:
        await WebSessionsScreen.open(context);
      case WebAccessMenuItem.crew:
        await CrewScreen.open(context);
      case WebAccessMenuItem.account:
        await WebAccountScreen.open(context);
    }
    if (!context.mounted) return;
    await ref.read(webAccessStatusProvider.notifier).refresh();
  }

  void _openEngineDebug(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EngineDebugScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final races = ref.watch(raceListProvider);
    final hasFinished = (races.valueOrNull ?? const <Race>[]).any(
      (race) => race.status == RaceStatus.finished,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listTitle, style: homeTitleStyle),
        actions: [
          IconButton(
            onPressed: () => unawaited(_openScanner(context)),
            icon: Icon(
              Icons.qr_code_scanner,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: l10n.webScanTooltip,
          ),
          // Csak debug-buildben: a 7-bg-b háttér-engine verifikáló képernyője.
          if (kDebugMode)
            IconButton(
              onPressed: () => _openEngineDebug(context),
              icon: const Icon(Icons.memory_outlined),
              tooltip: 'Engine debug',
            ),
          IconButton(
            onPressed: () => _openDebug(context),
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: l10n.viewerTitle,
          ),
          WebAccessMenu(
            onSelected: (item) => unawaited(_openWebAccess(context, ref, item)),
          ),
        ],
      ),
      body: WebAccessRefresher(
        child: Column(
          children: [
            WebAccessBanners(
              onOpenSessions: () => unawaited(
                _openWebAccess(context, ref, WebAccessMenuItem.sessions),
              ),
              onOpenCrew: () => unawaited(
                _openWebAccess(context, ref, WebAccessMenuItem.crew),
              ),
              onOpenScanner: () => unawaited(_openScanner(context)),
            ),
            Expanded(
              child: races.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(child: Text(l10n.listError)),
                data: (items) {
                  // Particionálás (ADR 0033): a fő lista a folyamatban lévő
                  // (elöl) és a nem indult versenyeket mutatja; a befejezettek
                  // az akció-sáv bal gombja mögötti modalba kerülnek.
                  final pending = [
                    ...items.where((race) => race.status == RaceStatus.active),
                    ...items.where(
                      (race) => race.status == RaceStatus.notStarted,
                    ),
                  ];
                  if (pending.isEmpty) {
                    return Center(child: Text(l10n.listEmpty));
                  }
                  // Nincs `separated`: a hairline a sor része, különben az
                  // utolsó sor alól hiányozna a vonal.
                  return ListView.builder(
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final race = pending[index];
                      return RaceListRow(
                        race: race,
                        onTap: () => _openDetail(context, race),
                      );
                    },
                  );
                },
              ),
            ),
            ListActionBar(
              onNewRace: () => _openSetup(context),
              onFinished: hasFinished
                  ? () => unawaited(_openFinished(context))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
