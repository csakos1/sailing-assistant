import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/widgets/section_label.dart';

/// Egy verseny részletei: státusz-csík, pálya-lista, és státuszfüggő akciók
/// (start/finish, törlés, valamint `notStarted` versenynél szerkesztés),
/// ADR 0044 3a. Az élő adatok a héj Műszerek fülén vannak (ADR 0056 D2): a
/// rajt után a héj oda vált, és ezt a képernyőt bezárja.
///
/// **Egy képernyő, három állapot** (D19). A `RaceStatus` négy helyen kapuz:
/// az AppBar-akcióknál, a státusz-csík meta-mezőjében, az aktív bója
/// él-sávjánál és az alsó akció-sávnál. Befejezett versenyen a track-kártya
/// és a stat-sor a pálya-lista **fölé** kerül, alsó sáv pedig nincs.
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

  // A `target` a képernyő friss (reaktív) példánya: egy szerkesztés után
  // a dialógus adatcellája így a mostani nevet és bójaszámot mutatja.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Race target,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.detailDeleteTitle,
      message: l10n.detailDeleteMessage,
      subject: (
        leading: null,
        name: target.name,
        trailing: l10n.listMarkCount(target.marks.length).toUpperCase(),
      ),
      actions: [
        ForetackDialogAction(label: l10n.detailDeleteCancel, value: false),
        ForetackDialogAction(
          label: l10n.detailDeleteConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
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
    final isFinished = current.status == RaceStatus.finished;
    final isActive = current.status == RaceStatus.active;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(current.name, style: screenTitleStyle),
        actions: [
          // Szerkesztés csak el nem indított versenyen (ADR 0029 D1).
          if (current.status == RaceStatus.notStarted)
            IconButton(
              onPressed: () => _openEdit(context, current),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.detailEdit,
            ),
          IconButton(
            onPressed: () => _delete(context, ref, current),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.detailDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailStatusStrip(race: current),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // A track-kártya, a stat-sor és — debug-buildben — a
                  // next-TWA elemzés a pálya-lista FÖLÉ kerül (ADR 0044 3a).
                  if (isFinished)
                    PostRaceAnalysisSection(
                      raceId: current.id,
                      raceName: current.name,
                      raceStartedAt: current.startedAt,
                      marks: current.marks,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: SectionLabel(text: l10n.detailCourseLabel),
                  ),
                  for (final (index, mark) in current.marks.indexed)
                    DetailMarkRow(
                      mark: mark,
                      // Csak futó versenyen van soron következő bója (D27).
                      isActive: isActive && index == current.activeMarkIndex,
                    ),
                ],
              ),
            ),
            // Befejezett versenyen nincs alsó sáv: a megosztás a teljes
            // képernyős térkép-nézeté, a törlés az AppBaré (D30).
            if (!isFinished)
              DetailActionBar(
                status: current.status,
                onStatusAction: () =>
                    isActive ? _finish(ref, current) : _start(ref, current),
              ),
          ],
        ),
      ),
    );
  }
}
