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
/// lévő (elöl) és a nem indult versenyek látszanak; a befejezettek egy bal
/// alsó FAB-gomb mögötti modalba kerülnek (csak ha van befejezett). A jobb
/// FAB a setup, az AppBar-action a Fázis 3 debug raw-viewer. Az
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
  /// meglévő detail-útvonalon nyitja meg (a sheet a `Race`-szel popol). A
  /// fogantyú-csíkot a sheet maga rajzolja (nincs `showDragHandle`).
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
    final scheme = Theme.of(context).colorScheme;
    final races = ref.watch(raceListProvider);
    final hasFinished = (races.valueOrNull ?? const <Race>[]).any(
      (race) => race.status == RaceStatus.finished,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.listTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
      // A bal (befejezett) + jobb (új verseny) FAB egy sorban, a Scaffold
      // a rendszer-navigációs sáv FÖLÉ teszi. A befejezett-gomb csak akkor
      // jelenik meg, ha van befejezett verseny; helyét különben egy üres
      // doboz tartja, hogy a + FAB jobbra maradjon.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasFinished)
              FloatingActionButton.extended(
                heroTag: 'finishedRacesFab',
                onPressed: () => _openFinished(context),
                backgroundColor: scheme.surfaceContainerHigh,
                foregroundColor: scheme.onSurface,
                icon: const Icon(Icons.history),
                label: Text(l10n.listFinishedRacesTitle),
              )
            else
              const SizedBox.shrink(),
            FloatingActionButton(
              heroTag: 'addRaceFab',
              onPressed: () => _openSetup(context),
              tooltip: l10n.listAddRace,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
      body: races.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.listError)),
        data: (items) {
          // Particionálás (ADR 0033): a fő lista a folyamatban lévő (elöl)
          // és a nem indult versenyeket mutatja, active-first; a befejezettek
          // a bal alsó FAB-gomb mögötti modalba kerülnek.
          final pending = [
            ...items.where((race) => race.status == RaceStatus.active),
            ...items.where((race) => race.status == RaceStatus.notStarted),
          ];
          if (pending.isEmpty) {
            return Center(child: Text(l10n.listEmpty));
          }
          return ListView.builder(
            // Alsó térköz, hogy az utolsó sor ne csússzon a FAB-ok mögé.
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final race = pending[index];
              return ListTile(
                title: Text(race.name),
                trailing: RaceStatusChip(status: race.status),
                onTap: () => _openDetail(context, race),
              );
            },
          );
        },
      ),
    );
  }
}
