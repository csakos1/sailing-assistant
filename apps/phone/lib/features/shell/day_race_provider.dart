import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// A beállításokban tárolt kézi Műszerek-választás (ADR 0055 D5). Ma csak
/// olvasott; aki írja (az U4 váltója), érvénytelenítse ezt is.
final AutoDisposeFutureProvider<InstrumentsRaceChoice?>
instrumentsRaceChoiceProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(settingsRepositoryProvider).readInstrumentsRaceChoice(),
);

/// A nap még el nem indult, tervezett versenye a sáv rajtidő-címkéjéhez
/// (ADR 0056 D2, `phone-ui-v1.md` §2), ugyanazzal a szabállyal, ami az
/// engine-nek is választ (ADR 0055 D5).
///
/// Nem időzít: a versenyek változásakor és az előtérbe kerüléskor (a héj
/// érvényteleníti) számol újra, így egy lejárt ablak címkéje legfeljebb a
/// következő ilyen pillanatig marad (mint a T4 szabálya, ADR 0055
/// „Pontosítás (T4)").
final AutoDisposeProvider<Race?> dayRaceProvider = Provider.autoDispose<Race?>((
  ref,
) {
  final races = ref.watch(raceListProvider).valueOrNull ?? const <Race>[];
  // Az aktív versenyeket kihagyjuk: azokat a sáv „ÉLŐ" címkéje jelzi, és
  // egy futó (nem kiválasztott) verseny se rejtse el a mai rajtidőt.
  final selected = const SelectInstrumentsRace()(
    races: [
      for (final candidate in races)
        if (candidate.status != RaceStatus.active) candidate,
    ],
    now: ref.watch(clockProvider)(),
    toLocal: ref.watch(localWallClockProvider),
    activeRaceLastRecordedAt: null,
    manualChoice: ref.watch(instrumentsRaceChoiceProvider).valueOrNull,
  );
  return selected?.status == RaceStatus.notStarted ? selected : null;
});
