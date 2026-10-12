import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/race_form_result.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/library/persist_race_marks_to_library.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Egy még el nem indított verseny szerkesztése.
///
/// Az űrlapot a közös [RaceForm] adja (edit-mód: `initialRace` a meglévő
/// verseny). Mentéskor a `Race.create` ugyanazzal az **id-vel** készíti újra
/// a versenyt — a rajtidővel és a rajthellyel együtt, különben a mentés
/// törölné őket (ADR 0055 T1 pontosítás) —, majd a
/// `raceRepositoryProvider.save` upsert + delete-and-rewrite felülírja a
/// race-sort és a bóyákat (ADR 0029 D4). A mentés után pop; a lista és a
/// detail a `watchRaces()` reaktív streamen frissül (ADR 0029 D5), és az
/// engine-t a lifecycle a friss példánnyal frissíti (ADR 0055 D8).
///
/// Csak `notStarted` versenyt szerkeszthetünk (ADR 0029 D1): a build az
/// `initialRace.status == notStarted`-ot asserteli — máshonnan hívva
/// programozói hiba. Az ellenőrzés a build-ben van, nem a const ctor
/// initializer-listájában, mert a `race.status` getter-hívás nem
/// konstans-kiértékelhető.
class RaceEditScreen extends ConsumerWidget {
  /// A szerkesztendő verseny; a státusza `notStarted` kell legyen (D1).
  const RaceEditScreen({required this.race, super.key});

  /// A szerkesztendő (notStarted) verseny.
  final Race race;

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    RaceFormResult result,
  ) async {
    // Ugyanaz az út, mint a create — csak az id a meglévő. A save az id
    // alapján dönt insert vs update között, és felülírja a régi bóyákat.
    final updated = Race.create(
      id: race.id,
      name: result.name,
      marks: result.marks,
      scheduledStartAt: result.scheduledStartAt,
      startPoint: result.startPoint,
    );
    await ref.read(raceRepositoryProvider).save(updated);
    // Best-effort: a bóják és a rajthely a könyvtárba is (ADR 0032 L5).
    await persistRaceMarksToLibrary(
      repository: ref.read(markLibraryRepositoryProvider),
      race: updated,
      savedAt: ref.read(clockProvider)(),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // D1 védőháló: csak notStarted verseny szerkeszthető (debug-only assert).
    assert(
      race.status == RaceStatus.notStarted,
      'A RaceEditScreen csak el nem indított versenyt szerkeszt.',
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 58,
        title: Text(l10n.editTitle, style: screenTitleStyle),
      ),
      body: RaceForm(
        initialRace: race,
        now: ref.watch(clockProvider),
        onSubmit: (result) => unawaited(_save(context, ref, result)),
      ),
    );
  }
}
