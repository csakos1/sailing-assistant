import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_list_provider.dart';

/// A Versenynapló év/hónap szerkezete (ADR 0044 D40, D41).
///
/// Tiszta projekció a [raceListProvider] fölé: ugyanabból a reaktív
/// stream-ből dolgozik, mint a lajstrom — nincs új RaceRepository-metódus,
/// nincs új lekérdezés és nincs séma-változás. A szűrést, a csoportosítást
/// és a rendezést a `BuildRaceLog` domain use case végzi, itt csak a
/// leképezés történik.
///
/// A `whenData` megtartja a loading/error ágat, így a napló-képernyő
/// ugyanazt a három állapotot kapja, mint a lista-képernyő. autoDispose: a
/// szerkezet a képernyővel együtt szűnik meg, újranyitáskor a stream
/// aktuális értékéből épül újra.
///
/// Az explicit AutoDisposeProvider típus tudatos, a [raceListProvider]
/// mintájára (specify_nonobvious_property_types).
final AutoDisposeProvider<AsyncValue<List<RaceLogYear>>> raceLogProvider =
    Provider.autoDispose<AsyncValue<List<RaceLogYear>>>((ref) {
      return ref.watch(raceListProvider).whenData(const BuildRaceLog().call);
    });
