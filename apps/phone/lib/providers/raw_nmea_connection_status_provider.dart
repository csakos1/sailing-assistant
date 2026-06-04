import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A debug raw-viewer SAJÁT NMEA-kapcsolatának állapota (Fázis 3, ADR 0006).
///
/// A 7-bg-d-ig a `connectionStatusProvider` szolgálta ezt is; azóta az a
/// provider az engine-tükör (a `raceSnapshotProvider`-ből derivál, §8.8). A
/// debug-viewer viszont a saját `nmeaStreamProvider`-kapcsolatát figyeli
/// (otthoni diagnosztika), ezért külön provider. Seedelt Notifier: szinkron a
/// `currentStatus`-ból, majd a `statusChanges`-re iratkozik (a broadcast NEM
/// replay-eli az utolsót — nincs AsyncLoading-villogás).
final rawNmeaConnectionStatusProvider =
    AutoDisposeNotifierProvider<
      RawNmeaConnectionStatusNotifier,
      ConnectionStatus
    >(
      RawNmeaConnectionStatusNotifier.new,
    );

/// A [rawNmeaConnectionStatusProvider] notifier-implementációja.
class RawNmeaConnectionStatusNotifier
    extends AutoDisposeNotifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.statusChanges.listen((status) => state = status);
    ref.onDispose(sub.cancel);
    return stream.currentStatus;
  }
}
