import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/race_setup/widgets/race_form.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/library/persist_race_marks_to_library.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/id_provider.dart';
import 'package:phone/providers/mark_library_repository_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Új verseny felvitele.
///
/// Az űrlapot a közös [RaceForm] adja (create-mód: `initialRace == null`); a
/// mentés a `Race.create` + `raceRepositoryProvider.save` úton megy, majd
/// visszanavigál a listához. A create-viselkedés szemantikailag változatlan
/// — a form-logika csak átköltözött a `RaceForm`-ba (ADR 0029 D2).
class RaceSetupScreen extends ConsumerWidget {
  const RaceSetupScreen({super.key});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    String name,
    List<Mark> marks,
  ) async {
    final race = Race.create(
      id: ref.read(idProvider)(),
      name: name,
      marks: marks,
    );
    await ref.read(raceRepositoryProvider).save(race);

    // Best-effort: a verseny bóyáit a könyvtárba is (ADR 0032 L5).
    await persistRaceMarksToLibrary(
      repository: ref.read(markLibraryRepositoryProvider),
      race: race,
      savedAt: ref.read(clockProvider)(),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: RaceForm(
        onSubmit: (name, marks) => unawaited(_save(context, ref, name, marks)),
      ),
    );
  }
}
