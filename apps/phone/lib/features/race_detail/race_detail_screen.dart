import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/live_race/live_race_screen.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_engine_session_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/widgets/race_status_chip.dart';

/// Egy verseny részletei: státusz, bóya-lista, és státuszfüggő akciók
/// (start/finish, törlés, valamint `notStarted` versenynél szerkesztés),
/// továbbá az élő képernyő megnyitása.
///
/// A listától kapott [race] egy pillanatkép. Az aktív futó verseny esetén az
/// `activeRaceProvider` élő (in-memory) állapotát mutatjuk; egyébként a
/// reaktív `raceListProvider` friss verzióját, a pillanatkép csak fallback —
/// így a szerkesztés utáni változás azonnal látszik (ADR 0029 D5). A
/// state-átmenetek az `activeRaceProvider`-en mennek (a `Race` factory-k +
/// `repo.save`). Az `AppLocalizations.of(context)!` biztonságos: a
/// `MaterialApp` regisztrálja a delegátorokat.
class RaceDetailScreen extends ConsumerWidget {
  const RaceDetailScreen({required this.race, super.key});

  /// A megnyitott verseny pillanatképe (a lista adta át).
  final Race race;

  // A reaktív listából keresi ki az aktuális verziót id alapján (D5); null,
  // ha a lista még nem töltött be vagy a verseny már nem szerepel benne.
  static Race? _findById(List<Race>? races, String id) {
    if (races == null) return null;
    for (final candidate in races) {
      if (candidate.id == id) return candidate;
    }
    return null;
  }

  Future<void> _start(WidgetRef ref, Race target) async {
    ref.read(activeRaceProvider.notifier).activeRace = target;
    await ref.read(activeRaceProvider.notifier).start();
  }

  Future<void> _finish(WidgetRef ref, Race target) async {
    ref.read(activeRaceProvider.notifier).activeRace = target;
    await ref.read(activeRaceProvider.notifier).finish();
  }

  // Az aktív race holderbe teszi a versenyt (a pre-start prediction is innen
  // él, ADR 0010), majd az élő képernyőre navigál. Ortogonális a
  // start/finish-től (SRP): a start state-et vált, ez navigál.
  void _openLive(BuildContext context, WidgetRef ref, Race target) {
    ref.read(activeRaceProvider.notifier).activeRace = target;
    ref.read(raceEngineSessionProvider.notifier).start();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LiveRaceScreen()),
      ),
    );
  }

  // A szerkesztő-képernyőre navigál (csak notStarted versenynél hívjuk).
  void _openEdit(BuildContext context, Race target) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RaceEditScreen(race: target),
        ),
      ),
    );
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
    final listValue = ref.watch(raceListProvider).valueOrNull;
    // Aktív futó versenynél az in-memory élő állapot az igazság; egyébként a
    // reaktív lista friss verziója, a pillanatkép csak fallback (ADR 0029 D5).
    final current = (active != null && active.id == race.id)
        ? active
        : (_findById(listValue, race.id) ?? race);

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          // Szerkesztés csak el nem indított versenyen (ADR 0029 D1).
          if (current.status == RaceStatus.notStarted)
            IconButton(
              onPressed: () => _openEdit(context, current),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.detailEdit,
            ),
          IconButton(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.detailDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
              child: ListView(
                children: [
                  for (final mark in current.marks)
                    ListTile(
                      leading: CircleAvatar(child: Text('${mark.sequence}')),
                      title: Text(mark.name),
                      subtitle: Text(_formatPosition(mark.position)),
                      trailing: mark.roundedAt != null
                          ? const Icon(Icons.check_circle_outline)
                          : null,
                    ),
                  // Post-race elemzés a befejezett verseny alatt: a track +
                  // statok release-ben is, a next-TWA a szekción belül debug
                  // mögött (ADR 0034 Addendum 3 A3-D4).
                  if (current.status == RaceStatus.finished)
                    PostRaceAnalysisSection(
                      raceId: current.id,
                      raceName: current.name,
                      raceStartedAt: current.startedAt,
                      marks: current.marks,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAction(context, ref, current, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    WidgetRef ref,
    Race current,
    AppLocalizations l10n,
  ) {
    final stateButton = switch (current.status) {
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

    if (current.status == RaceStatus.finished) {
      return stateButton;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonal(
          onPressed: () => _openLive(context, ref, current),
          child: Text(l10n.liveOpen),
        ),
        const SizedBox(height: 8),
        stateButton,
      ],
    );
  }

  String _formatPosition(Coordinate position) =>
      '${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}';
}
