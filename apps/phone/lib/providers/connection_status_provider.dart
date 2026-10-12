import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/engine_session_provider.dart';
import 'package:phone/providers/engine_session_state.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A kapcsolat-állapot az engine-snapshotból tükrözve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `nmeaStreamProvider.statusChanges`-re iratkozott; azóta az
/// engine birtokolja a kapcsolatot, és ez a provider a `raceSnapshotProvider`
/// `connectionStatus` mezőjét tükrözi. Snapshot nélkül álló engine mellett
/// (induláskor, kézi „Leállítás" után) `Disconnected()`: ilyenkor nincs mire
/// várni, a „Csatlakozás…" félrevezetne (ADR 0056, U2). Próba vagy futó engine
/// mellett `Connecting()` (várjuk az engine első pillanatképét). A
/// warning-suppression mindkettőt nem-`Connected`-ként kezeli (ADR 0014), így
/// az első snapshotig a gateway-disconnected jelzés látszik.
final connectionStatusProvider =
    AutoDisposeNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
      ConnectionStatusNotifier.new,
    );

/// A [connectionStatusProvider] notifier-implementációja.
class ConnectionStatusNotifier extends AutoDisposeNotifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    final snapshot = ref.watch(raceSnapshotProvider);
    if (snapshot != null) return snapshot.connectionStatus;
    return switch (ref.watch(engineSessionProvider)) {
      EngineStopped() => const Disconnected(),
      EngineProbing() || EngineRunning() => const Connecting(),
    };
  }
}
