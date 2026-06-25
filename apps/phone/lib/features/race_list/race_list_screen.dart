import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/engine/engine_debug_screen.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_list/widgets/finished_races_sheet.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// A versenyek listája — az app `home` képernyője.
///
/// A `raceListProvider` reaktív projekcióját mutatja (loading/error/data).
/// A fő lista státusz szerint particionál (ADR 0033): csak a folyamatban
/// lévő (elöl) és a nem indult versenyek látszanak; a befejezettek egy alsó
/// sor mögötti modalba kerülnek. Sorra koppintva a detail nyílik, a FAB a
/// setup, az AppBar-action a Fázis 3 debug raw-viewer. Az
/// `AppLocalizations.of(context)!` biztonságos: a `MaterialApp` regisztrálja
/// a delegátorokat.
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
  /// meglévő detail-útvonalon nyitja meg (a sheet a `Race`-szel popol).
  Future<void> _openFinished(BuildContext context) async {
    final picked = await showModalBottomSheet<Race>(
      context: context,
      builder: (_) => const FinishedRacesSheet(),
    );
    if (picked != null && context.mounted) {
      _openDetail(context, picked);
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listTitle),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSetup(context),
        tooltip: l10n.listAddRace,
        child: const Icon(Icons.add),
      ),
      body: races.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.listError)),
        data: (items) {
          // Particionálás (ADR 0033): a fő lista a folyamatban lévő (elöl)
          // és a nem indult versenyeket mutatja; a befejezettek a modalba
          // kerülnek. Mindkét csoport a watchRaces() sorrendjét tartja.
          final pending = [
            ...items.where((race) => race.status == RaceStatus.active),
            ...items.where((race) => race.status == RaceStatus.notStarted),
          ];
          final finished = [
            ...items.where((race) => race.status == RaceStatus.finished),
          ];

          return Column(
            children: [
              Expanded(
                child: pending.isEmpty
                    ? Center(child: Text(l10n.listEmpty))
                    : ListView.builder(
                        itemCount: pending.length,
                        itemBuilder: (context, index) {
                          final race = pending[index];
                          return ListTile(
                            title: Text(race.name),
                            subtitle: Text(
                              l10n.listMarkCount(race.marks.length),
                            ),
                            trailing: RaceStatusChip(status: race.status),
                            onTap: () => _openDetail(context, race),
                          );
                        },
                      ),
              ),
              if (finished.isNotEmpty) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.listFinishedRaces(finished.length)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openFinished(context),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
