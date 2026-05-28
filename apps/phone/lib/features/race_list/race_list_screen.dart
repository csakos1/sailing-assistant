import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/features/race_detail/race_detail_screen.dart';
import 'package:phone/features/race_setup/race_setup_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// A versenyek listája — az app `home` képernyője.
///
/// A `raceListProvider` reaktív projekcióját mutatja (loading/error/data).
/// Sorra koppintva a detail nyílik, a FAB a setup, az AppBar-action a Fázis 3
/// debug raw-viewer. Az `AppLocalizations.of(context)!` biztonságos: a
/// `MaterialApp` regisztrálja a delegátorokat.
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

  void _openDebug(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const RawNmeaViewerScreen()),
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
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.listEmpty))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final race = items[index];
                  return ListTile(
                    title: Text(race.name),
                    subtitle: Text(l10n.listMarkCount(race.marks.length)),
                    trailing: RaceStatusChip(status: race.status),
                    onTap: () => _openDetail(context, race),
                  );
                },
              ),
      ),
    );
  }
}
