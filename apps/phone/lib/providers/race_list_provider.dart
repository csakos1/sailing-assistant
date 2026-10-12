import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/pending_race_deletions_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Az összes verseny reaktív listája a felületnek (ADR 0009 D4), a függő
/// törlések nélkül (ADR 0056 D6).
///
/// A RaceRepository.watchRaces() köré épül. A függő törléseket a
/// [pendingRaceDeletionsProvider] adja: egy törölt verseny a megerősítés
/// után azonnal eltűnik minden fülről (Versenyek, napló, Műszerek, sáv), a
/// visszavonás visszahozza. Az engine-lifecycle és a nap versenyének
/// kiválasztása szándékosan a repository streamjét olvassa: az engine-t a
/// valódi törlés dönti újra, nem a függő.
///
/// A halmaz változása nem építi újra a providert (egy `ref.watch` újra
/// feliratkozna, és egy pillanatra betöltést mutatna), hanem a legutóbbi
/// listát szűri újra ugyanabba a streambe.
///
/// autoDispose: a stream megszűnik, amint az utolsó figyelő elhagyja a
/// fát. Az explicit AutoDisposeStreamProvider típus tudatos: a
/// `StreamProvider.autoDispose<…>` factory más típust ad vissza, mint amit a
/// `StreamProvider` név sugall (specify_nonobvious_property_types).
final AutoDisposeStreamProvider<List<Race>> raceListProvider =
    StreamProvider.autoDispose<List<Race>>((ref) {
      final controller = StreamController<List<Race>>();
      List<Race>? latest;

      void emit() {
        final races = latest;
        if (races == null || controller.isClosed) return;
        final pending = ref.read(pendingRaceDeletionsProvider);
        controller.add(
          pending.isEmpty
              ? races
              : [
                  for (final race in races)
                    if (!pending.contains(race.id)) race,
                ],
        );
      }

      final subscription = ref
          .watch(raceRepositoryProvider)
          .watchRaces()
          .listen((races) {
            latest = races;
            emit();
          }, onError: controller.addError);
      ref
        ..listen<Set<String>>(pendingRaceDeletionsProvider, (_, _) => emit())
        ..onDispose(() {
          unawaited(subscription.cancel());
          unawaited(controller.close());
        });
      return controller.stream;
    });
