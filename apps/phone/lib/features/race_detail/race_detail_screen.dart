import 'dart:async';
import 'dart:developer' as developer;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_detail/detail_action.dart';
import 'package:phone/features/race_detail/widgets/detail_action_bar.dart';
import 'package:phone/features/race_detail/widgets/detail_course_mark_row.dart';
import 'package:phone/features/race_detail/widgets/detail_start_point_row.dart';
import 'package:phone/features/race_detail/widgets/post_race_analysis_section.dart';
import 'package:phone/features/race_detail/widgets/race_detail_strip.dart';
import 'package:phone/features/race_edit/race_edit_screen.dart';
import 'package:phone/format/race_day_format.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/widgets/section_label.dart';

/// Egy verseny részletei: státusz-csík, pálya-lista, és státuszfüggő akciók
/// (rajt/cél, törlés, valamint `notStarted` versenynél szerkesztés),
/// ADR 0044 3a, makett 32a–c (ADR 0056 D4, U6). Az élő adatok a héj
/// Műszerek fülén vannak (ADR 0056 D2): a rajt után a héj oda vált, és ezt a
/// képernyőt bezárja.
///
/// A rajt és a cél megerősítést kér (`phone-ui-v1.md` §9). A dialógus után
/// a verseny friss állapota dönt: ha közben az engine magától rajtolt
/// (ADR 0055 D6), a kézi rajt elmarad, és nem írja felül a tervezett
/// rajtidőt.
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

  // A képernyő friss példánya (D5): aktív futó versenynél az in-memory élő
  // állapot, egyébként a reaktív lista, a pillanatkép csak fallback.
  Race _currentOf(Race? active, List<Race>? races) =>
      (active != null && active.id == race.id)
      ? active
      : (_findById(races, race.id) ?? race);

  Race _readCurrent(WidgetRef ref) => _currentOf(
    ref.read(activeRaceProvider),
    ref.read(raceListProvider).valueOrNull,
  );

  Future<void> _confirmStart(
    BuildContext context,
    WidgetRef ref,
    Race target,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final activeRace = ref.read(activeRaceProvider.notifier);
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.instrumentsStartTitle,
      message: _startMessage(ref, l10n, target),
      subject: (leading: null, name: target.name, trailing: null),
      actions: [
        ForetackDialogAction(label: l10n.instrumentsStartCancel, value: false),
        ForetackDialogAction(label: l10n.instrumentsStartConfirm, value: true),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    // A dialógus alatt az engine maga is rajtolhatott a tervezett időben:
    // ilyenkor a friss példány már nem notStarted, és a kézi rajt elmarad.
    final fresh = _readCurrent(ref);
    if (fresh.status != RaceStatus.notStarted) return;
    activeRace.activeRace = fresh;
    try {
      await activeRace.start();
    } on Object catch (error) {
      // Egy mentési hiba nem dönthet le a vízen (mint a Műszerek „Rajt
      // most"-jánál): a rajt elmarad, a felhasználó újrapróbálhatja.
      developer.log('manual start failed: $error', name: 'RaceDetail');
    }
  }

  // Tervezett rajtnál a dialógus kimondja, hogy a verseny nem a tervezett
  // időben, hanem most indul.
  String _startMessage(WidgetRef ref, AppLocalizations l10n, Race target) {
    final scheduledStartAt = target.scheduledStartAt;
    if (scheduledStartAt == null) return l10n.instrumentsStartMessage;
    final label = _scheduledStartLabel(ref, l10n, scheduledStartAt);
    return l10n.detailStartScheduledMessage(label.toLowerCase());
  }

  // A mai rajtnál csak az idő („09:00"), más napon a nap is („OKT. 13.
  // 09:00"), hogy a felirat ne ígérjen mai rajtot.
  String _scheduledStartLabel(
    WidgetRef ref,
    AppLocalizations l10n,
    DateTime scheduledStartAt,
  ) {
    final toLocal = ref.read(localWallClockProvider);
    return formatRaceStart(
      l10n,
      toLocal(scheduledStartAt),
      localToday: toLocal(ref.read(clockProvider)()),
    );
  }

  Future<void> _confirmFinish(
    BuildContext context,
    WidgetRef ref,
    Race target,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final activeRace = ref.read(activeRaceProvider.notifier);
    final confirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.detailFinishTitle,
      message: l10n.detailFinishMessage,
      subject: (leading: null, name: target.name, trailing: null),
      actions: [
        ForetackDialogAction(label: l10n.detailFinishCancel, value: false),
        ForetackDialogAction(
          label: l10n.detailFinishConfirm,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    // A dialógus alatt az engine az utolsó bójánál maga is lezárhatta.
    final fresh = _readCurrent(ref);
    if (fresh.status != RaceStatus.active) return;
    activeRace.activeRace = fresh;
    try {
      await activeRace.finish();
    } on Object catch (error) {
      developer.log('manual finish failed: $error', name: 'RaceDetail');
    }
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
    if (confirmed != true || !context.mounted) return;
    // A dialógus alatt az engine magától rajtolhatott (ADR 0055 D6): futó
    // versenyt nem törlünk.
    if (_readCurrent(ref).status == RaceStatus.active) return;

    // A DB-törlés csak a visszavonási ablak után fut (ADR 0056 D6); a
    // verseny addig is eltűnik a listákból.
    final deletions = ref.read(pendingRaceDeletionsProvider.notifier)
      ..schedule(target.id);
    // Ha a törölt verseny volt a kiválasztott, ürítjük az in-memory
    // holdert; a visszavonás visszaadja, ha közben nem lett más
    // kiválasztva. Futó verseny ide nem jut (nincs kuka), tehát az
    // engine-t ez nem érinti.
    final selection = ref.read(activeRaceProvider.notifier);
    final wasSelected = selection.activeRace?.id == target.id;
    if (wasSelected) selection.activeRace = null;

    void undo() {
      // Egy késői koppintás a már törölt versenyt nem választhatja ki.
      final isRestored = deletions.undo(target.id);
      if (isRestored && wasSelected && selection.activeRace == null) {
        selection.activeRace = target;
      }
    }

    // A snackbar a gyökér messengeren jelenik meg, így a pop után a héj
    // fölött látszik.
    final snackBar = foretackSnackBar(
      context,
      message: l10n.detailDeletedMessage,
      duration: raceDeletionUndoWindow,
      action: ForetackSnackBarAction(
        label: l10n.detailDeleteUndo,
        onPressed: undo,
      ),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    // A sorban álló snackbarok is mennek: a VISSZAVONÁS-nak most kell
    // látszania, nem a visszavonási ablak után.
    messenger
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  Widget? _actionBar(
    BuildContext context,
    WidgetRef ref,
    Race current,
    DetailAction? action,
  ) {
    final l10n = AppLocalizations.of(context)!;
    void start() => unawaited(_confirmStart(context, ref, current));
    return switch (action) {
      null => null,
      DetailScheduledStart(:final scheduledStartAt) =>
        DetailActionBar.scheduled(
          automaticStartLabel: _scheduledStartLabel(
            ref,
            l10n,
            scheduledStartAt,
          ),
          onStart: start,
        ),
      DetailStart() => DetailActionBar.start(onStart: start),
      DetailFinish() => DetailActionBar.finish(
        onFinish: () => unawaited(_confirmFinish(context, ref, current)),
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeRaceProvider);
    final listValue = ref.watch(raceListProvider).valueOrNull;
    // Aktív futó versenynél az in-memory élő állapot az igazság; egyébként a
    // reaktív lista friss verziója, a pillanatkép csak fallback (ADR 0029 D5).
    final current = _currentOf(active, listValue);
    final scheme = Theme.of(context).colorScheme;
    final isFinished = current.status == RaceStatus.finished;
    final isActive = current.status == RaceStatus.active;
    final toLocal = ref.watch(localWallClockProvider);
    final now = ref.watch(clockProvider)();
    final startPoint = current.startPoint;
    final startedAt = current.startedAt;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        shape: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
        title: Text(current.name, style: screenTitleStyle),
        actions: [
          // Szerkesztés csak el nem indított versenyen (ADR 0029 D1).
          if (current.status == RaceStatus.notStarted)
            IconButton(
              onPressed: () => _openEdit(context, current),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.detailEdit,
            ),
          // Futó versenyen nincs törlés: az engine ír hozzá, előbb a Cél
          // zárja le (ADR 0056 „Pontosítás (U8)").
          if (current.status != RaceStatus.active)
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
            RaceDetailStrip(race: current),
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
                  if (startPoint != null)
                    DetailStartPointRow(
                      startPoint: startPoint,
                      localStartedAt: startedAt == null
                          ? null
                          : toLocal(startedAt),
                    ),
                  for (final (index, mark) in current.marks.indexed)
                    DetailCourseMarkRow(
                      mark: mark,
                      toLocal: toLocal,
                      // Csak futó versenyen van soron következő bója (D27).
                      isActive: isActive && index == current.activeMarkIndex,
                    ),
                ],
              ),
            ),
            // Befejezett versenyen nincs alsó sáv: a megosztás a teljes
            // képernyős térkép-nézeté, a törlés az AppBaré (D30).
            ?_actionBar(
              context,
              ref,
              current,
              detailActionOf(race: current, now: now, toLocal: toLocal),
            ),
          ],
        ),
      ),
    );
  }
}
