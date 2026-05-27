import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A kapcsolat-állapot Riverpod-providere a UI connection-badge-hez és a
/// warning-rendszerhez (§11.2, Fázis 6).
///
/// Seedelt `AutoDisposeNotifierProvider`: a `build()` SZINKRON a kliens
/// `currentStatus`-ából veszi a kezdőértéket (a `statusChanges` broadcast NEM
/// replay-eli az utolsót), majd a változásokra iratkozik — így a badge
/// azonnal helyes értéket mutat, nincs `AsyncLoading`-villogás (ADR 0006).
final connectionStatusProvider =
    AutoDisposeNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>(
      ConnectionStatusNotifier.new,
    );

/// A [connectionStatusProvider] notifier-implementációja.
class ConnectionStatusNotifier extends AutoDisposeNotifier<ConnectionStatus> {
  @override
  ConnectionStatus build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.statusChanges.listen((status) => state = status);
    ref.onDispose(sub.cancel);
    return stream.currentStatus;
  }
}
