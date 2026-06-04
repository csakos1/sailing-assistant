import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A hajó pillanatnyi állapota az engine-snapshotból tükrözve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `nmeaStreamProvider.events`-et foldolta a domain
/// `BoatStateReducer`-rel; azóta a fold az engine háttér-izolátumában fut, és
/// ez a provider a `raceSnapshotProvider` `boatState` mezőjét tükrözi
/// (read-only). Még meg nem érkezett snapshot esetén üres [BoatState]-tel
/// seedel az app-órából (`clockProvider`). Seedelt Notifier marad a §8.6-
/// idióma szerint; a `build()` már nem foldol, hanem a snapshotból derivál.
final boatStateProvider =
    AutoDisposeNotifierProvider<BoatStateNotifier, BoatState>(
      BoatStateNotifier.new,
    );

/// A [boatStateProvider] notifier-implementációja.
class BoatStateNotifier extends AutoDisposeNotifier<BoatState> {
  @override
  BoatState build() {
    final clock = ref.watch(clockProvider);
    return ref.watch(raceSnapshotProvider)?.boatState ??
        BoatState(lastUpdate: clock());
  }
}
