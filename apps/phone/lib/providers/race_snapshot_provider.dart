import 'package:data/data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_engine_host_provider.dart';

/// A háttér-engine legfrissebb [RaceSnapshot]-ja — a telefon-UI read-only
/// tükrének gyökere (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// Seedelt `AutoDisposeNotifier` a 8.6-idióma szerint: a `build()` a
/// `raceEngineHostProvider.snapshots` streamre iratkozik, a legfrissebb
/// snapshotot tartja, és `ref.onDispose(sub.cancel)`-lal takarít. `null`-lal
/// seedel (még nem érkezett snapshot); a derivált providerek erre adnak
/// értelmes fallbacket. `autoDispose`: a live screen életében él, de az engine
/// ettől függetlenül fut tovább (ADR 0016 — a háttér-izolátum a tulajdonos).
final raceSnapshotProvider =
    AutoDisposeNotifierProvider<RaceSnapshotNotifier, RaceSnapshot?>(
      RaceSnapshotNotifier.new,
    );

/// A [raceSnapshotProvider] notifier-implementációja.
class RaceSnapshotNotifier extends AutoDisposeNotifier<RaceSnapshot?> {
  @override
  RaceSnapshot? build() {
    final host = ref.watch(raceEngineHostProvider);
    final sub = host.snapshots.listen((snapshot) => state = snapshot);
    ref.onDispose(sub.cancel);
    return null;
  }
}
