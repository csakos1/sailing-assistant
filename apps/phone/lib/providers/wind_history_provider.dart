import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// TWD-observation történet a wind-shift trendhez
/// (ADR 0010 D1, ARCHITECTURE.md 8.6).
///
/// Seedelt `AutoDisposeNotifier`: üres listával indul, majd minden
/// [WindEvent]-nél, ha van [WindData.trueDirectionGround], egy
/// [WindObservation]-t fűz a pufferbe. A puffer **30 perces, idő-nyírt** a
/// legfrissebb observation időbélyegéhez képest — korlátos memória, és bőven
/// fedi a `CalculateWindShiftTrend` (default 10 perces) ablakát. A tényleges
/// trend-ablakot a `windShiftTrendProvider` (5c) alkalmazza, nem ez.
final windHistoryProvider =
    AutoDisposeNotifierProvider<WindHistoryNotifier, List<WindObservation>>(
      WindHistoryNotifier.new,
    );

/// A [windHistoryProvider] notifier-implementációja.
class WindHistoryNotifier extends AutoDisposeNotifier<List<WindObservation>> {
  // A puffer hossza: bőven a trend-ablak (10 perc) fölött, hogy a window-
  // váltás (runtime konfig, 5f) ne ürítse ki a történetet.
  static const Duration _bufferWindow = Duration(minutes: 30);

  @override
  List<WindObservation> build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      if (event case WindEvent(:final data)) {
        final twd = data.trueDirectionGround;
        if (twd == null) {
          return;
        }
        state = _appended(
          state,
          WindObservation(twd: twd, timestamp: data.timestamp),
        );
      }
    });
    ref.onDispose(sub.cancel);
    return const <WindObservation>[];
  }

  // Hozzáfűz, majd a legfrissebb observationhöz képest 30 percnél régebbieket
  // levág. Új lista (immutable state-csere), nem in-place mutáció.
  List<WindObservation> _appended(
    List<WindObservation> current,
    WindObservation observation,
  ) {
    final next = [...current, observation];
    final cutoff = observation.timestamp.subtract(_bufferWindow);
    return next.where((o) => o.timestamp.isAfter(cutoff)).toList();
  }
}
