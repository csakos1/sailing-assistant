import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/race_list/race_list_entries.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_list_provider.dart';

/// A lajstrom sorai és a pillanat, amihez a „ma" számolódott.
///
/// A `now` a meta-sornak is kell (az év-összevetéshez), hogy a sorrend, a
/// kiemelés és a nap-felirat egyetlen órából jöjjön.
typedef RaceListView = ({List<RaceListEntry> entries, DateTime now});

/// A Versenyek fül sorai, a lajstrom sorrendjében (ADR 0056 D4).
///
/// Nem időzít: a „ma" a versenyek változásakor és előtérbe kerüléskor
/// számol újra (a héj érvényteleníti), mint a nap versenye
/// (`dayRaceProvider`). Egy éjfélen át nyitva hagyott lista a következő
/// előtérig a tegnapi kiemelést mutatja.
final AutoDisposeProvider<AsyncValue<RaceListView>> raceListEntriesProvider =
    Provider.autoDispose((ref) {
      final now = ref.watch(clockProvider)();
      final toLocal = ref.watch(localWallClockProvider);
      return ref
          .watch(raceListProvider)
          .whenData(
            (races) => (
              entries: raceListEntriesOf(
                races: races,
                now: now,
                toLocal: toLocal,
              ),
              now: now,
            ),
          );
    });
