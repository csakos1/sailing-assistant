import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A kapcsolat-állapot az engine-snapshotból tükrözve
/// (ADR 0017 addendum A4, ARCHITECTURE.md 8.8).
///
/// A 7-bg-d előtt a `nmeaStreamProvider.statusChanges`-re iratkozott; azóta az
/// engine birtokolja a kapcsolatot, és ez a provider a `raceSnapshotProvider`
/// `connectionStatus` mezőjét tükrözi. Még meg nem érkezett snapshot esetén
/// `Connecting()` (várjuk az engine első pillanatképét); a warning-suppression
/// ezt nem-`Connected`-ként kezeli (ADR 0014), így az első snapshotig a
/// gateway-disconnected jelzés látszik, ami az első pillanatképpel feloldódik.
final connectionStatusProvider =
    AutoDisposeNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
      ConnectionStatusNotifier.new,
    );

/// A [connectionStatusProvider] notifier-implementációja.
class ConnectionStatusNotifier extends AutoDisposeNotifier<ConnectionStatus> {
  @override
  ConnectionStatus build() =>
      ref.watch(raceSnapshotProvider)?.connectionStatus ?? const Connecting();
}
