import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// TWD-observation történet a wind-shift trendhez
/// (ADR 0010 D1, ARCHITECTURE.md 8.6).
///
/// Seedelt `AutoDisposeNotifier`: üres listával indul, majd minden
/// [WindEvent]-nél, ha van [WindData.trueDirectionGround], egy
/// [WindObservation]-t fűz a pufferbe. Az append + idő-nyírás (default
/// 30 perc) a domain `WindHistoryReducer`-ében él (ADR 0017 D2); a
/// tényleges trend-ablakot a `windShiftTrendProvider` (5c) alkalmazza.
final windHistoryProvider =
    AutoDisposeNotifierProvider<WindHistoryNotifier, List<WindObservation>>(
      WindHistoryNotifier.new,
    );

/// A [windHistoryProvider] notifier-implementációja.
class WindHistoryNotifier extends AutoDisposeNotifier<List<WindObservation>> {
  @override
  List<WindObservation> build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      if (event case WindEvent(:final data)) {
        final twd = data.trueDirectionGround;
        if (twd == null) {
          return;
        }
        state = const WindHistoryReducer()(
          state,
          WindObservation(twd: twd, timestamp: data.timestamp),
        );
      }
    });
    ref.onDispose(sub.cancel);
    return const <WindObservation>[];
  }
}
