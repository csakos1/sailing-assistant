import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Egy még el nem indított verseny szerkesztése.
///
/// Az űrlapot a közös [RaceForm] adja (edit-mód: `initialRace` a meglévő
/// verseny). Mentéskor a `Race.create` ugyanazzal az **id-vel** készíti újra
/// a versenyt, majd a `raceRepositoryProvider.save` upsert + delete-and-
/// rewrite felülírja a race-sort és a bóyákat (ADR 0029 D4) — ugyanaz a
/// kód-út, mint a create, csak az id a meglévő. A mentés után pop; a lista és
/// a detail a `watchRaces()` reaktív streamen frissül (ADR 0029 D5).
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
    String name,
    List<Mark> marks,
  ) async {
    // Ugyanaz az út, mint a create — csak az id a meglévő. A save az id
    // alapján dönt insert vs update között, és felülírja a régi bóyákat.
    final updated = Race.create(id: race.id, name: name, marks: marks);
    await ref.read(raceRepositoryProvider).save(updated);

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
      appBar: AppBar(title: Text(l10n.editTitle)),
      body: RaceForm(
        initialRace: race,
        onSubmit: (name, marks) => unawaited(_save(context, ref, name, marks)),
      ),
    );
  }
}
