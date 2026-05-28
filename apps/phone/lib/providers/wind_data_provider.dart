import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A legfrissebb szél-snapshot az NMEA esemény-folyamból
/// (ADR 0010 D1, ARCHITECTURE.md 8.6).
///
/// Seedelt `AutoDisposeNotifier`: `null`-lal indul (még nincs szél), majd a
/// [NmeaStream.events] minden [WindEvent]-jénél a hordozott [WindData]-ra
/// vált. A nem-szél eseményeket figyelmen kívül hagyja.
final windDataProvider =
    AutoDisposeNotifierProvider<WindDataNotifier, WindData?>(
      WindDataNotifier.new,
    );

/// A [windDataProvider] notifier-implementációja.
class WindDataNotifier extends AutoDisposeNotifier<WindData?> {
  @override
  WindData? build() {
    final stream = ref.watch(nmeaStreamProvider);
    final sub = stream.events.listen((event) {
      if (event case WindEvent(:final data)) {
        state = data;
      }
    });
    ref.onDispose(sub.cancel);
    return null;
  }
}
