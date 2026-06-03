import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A hajó pillanatnyi állapota az NMEA esemény-folyamból foldolva
/// (ADR 0010 D1, ARCHITECTURE.md 8.6).
///
/// Seedelt `AutoDisposeNotifier` a `connectionStatusProvider` (8.3)
/// mintájára: a `build()` üres [BoatState]-tel seedel az app-órából, a
/// [NmeaStream.events]-re iratkozik, és minden eseményt a domain
/// `BoatStateReducer`-e (ADR 0017 D2) foldol be. A `lastUpdate` mindig a
/// `clockProvider`-óra (receipt-idő); az [InstrumentTimeEvent]
/// GPS-instantja **csak** az `instrumentTimeUtc`-be megy.
final boatStateProvider =
    AutoDisposeNotifierProvider<BoatStateNotifier, BoatState>(
      BoatStateNotifier.new,
    );

/// A [boatStateProvider] notifier-implementációja.
class BoatStateNotifier extends AutoDisposeNotifier<BoatState> {
  @override
  BoatState build() {
    final clock = ref.watch(clockProvider);
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      state = const BoatStateReducer()(state, event, clock());
    });
    ref.onDispose(sub.cancel);
    return BoatState(lastUpdate: clock());
  }
}
