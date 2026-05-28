import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// Egy verseny részletei: státusz, bóya-lista, és státuszfüggő start/finish
/// + törlés akciók.
///
/// A listától kapott [race] egy pillanatkép; ha ez a verseny az aktív, az
/// `activeRaceProvider` élő (in-memory) állapotát mutatjuk, hogy a
/// start/finish azonnal látszódjon. A state-átmenetek az
/// `activeRaceProvider`-en mennek (a `Race` factory-k + `repo.save`). Az
/// `AppLocalizations.of(context)!` biztonságos: a `MaterialApp` regisztrálja
/// a delegátorokat.
class RaceDetailScreen extends ConsumerWidget {
  const RaceDetailScreen({required this.race, super.key});

  /// A megnyitott verseny pillanatképe (a lista adta át).
  final Race race;

  Future<void> _start(WidgetRef ref, Race target) async {
    ref.read(activeRaceProvider.notifier).activeRace = target;
    await ref.read(activeRaceProvider.notifier).start();
  }

  Future<void> _finish(WidgetRef ref, Race target) async {
    ref.read(activeRaceProvider.notifier).activeRace = target;
    await ref.read(activeRaceProvider.notifier).finish();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        content: Text(l10n.detailDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.detailDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.detailDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(raceRepositoryProvider).delete(race.id);
    // Ha a törölt verseny volt az aktív, ürítjük az in-memory holdert.
    if (ref.read(activeRaceProvider)?.id == race.id) {
      ref.read(activeRaceProvider.notifier).activeRace = null;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeRaceProvider);
    // Ha ez a verseny az aktív, az élő állapotot mutatjuk.
    final current = (active != null && active.id == race.id) ? active : race;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.detailDelete,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RaceStatusChip(status: current.status),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: current.marks.length,
              itemBuilder: (context, index) {
                final mark = current.marks[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${mark.sequence}')),
                  title: Text(mark.name),
                  subtitle: Text(_formatPosition(mark.position)),
                  trailing: mark.roundedAt != null
                      ? const Icon(Icons.check_circle_outline)
                      : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildAction(ref, current, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(WidgetRef ref, Race current, AppLocalizations l10n) {
    return switch (current.status) {
      RaceStatus.notStarted => FilledButton(
        onPressed: () => _start(ref, current),
        child: Text(l10n.detailStart),
      ),
      RaceStatus.active => FilledButton(
        onPressed: () => _finish(ref, current),
        child: Text(l10n.detailFinish),
      ),
      RaceStatus.finished => const SizedBox.shrink(),
    };
  }

  String _formatPosition(Coordinate position) =>
      '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}';
}
