import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/engine/engine_debug_screen.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/widgets/list_action_bar.dart';
import 'package:phone/features/race_list/widgets/race_list_row.dart';
import 'package:phone/features/race_log/race_log_screen.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
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
/// Az AppBar-action a Fázis 3 debug raw-viewer; debug-buildben mellette a
/// háttér-engine verifikáló képernyője. Az `AppLocalizations.of(context)!`
/// biztonságos: a `MaterialApp` regisztrálja a delegátorokat.
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
        ],
      ),
      body: Column(
        children: [
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
    );
  }
}
