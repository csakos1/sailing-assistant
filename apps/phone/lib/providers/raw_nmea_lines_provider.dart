import 'package:data/data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

/// A debug raw-viewer Riverpod-providere: a [nmeaStreamProvider]-ből nyers
/// (még nem dekódolt) NMEA sorokat gyűjt egy korlátos ring-bufferbe (utolsó
/// [RawNmeaLinesNotifier._maxLines] sor) az unbounded memória ellen (ADR
/// 0006).
///
/// A forrást típus-ellenőrzi: ha NEM [RawNmeaLineSource] (pl. fake/replay
/// stream nyers-sor nélkül), a viewer üresen, gracefully degradál — DIP, és
/// forward-compatible a nem-TCP gateway-ekhez.
final rawNmeaLinesProvider =
    AutoDisposeNotifierProvider<RawNmeaLinesNotifier, List<String>>(
      RawNmeaLinesNotifier.new,
    );

/// A [rawNmeaLinesProvider] notifier-implementációja.
class RawNmeaLinesNotifier extends AutoDisposeNotifier<List<String>> {
  // A ring-buffer felső korlátja: 200 sor ~20 másodperc NMEA forgalmat fed le
  // 10 Hz mellett — bőven elég a debug-viewerhez, és nem szivárog a memória.
  static const int _maxLines = 200;

  @override
  List<String> build() {
    final source = ref.watch(nmeaStreamProvider);
    // A `RawNmeaLineSource` és az `NmeaStream` független abstract osztályok
    // (DIP); Dart NEM promotál unrelated interfészek között `is!` után — a
    // pattern-matching adja a tiszta, tipizált hivatkozást a nyers-sor
    // felületre, cast nélkül.
    if (source case final RawNmeaLineSource rawSource) {
      final sub = rawSource.rawLines.listen((line) {
        final next = <String>[...state, line];
        state = next.length > _maxLines
            ? next.sublist(next.length - _maxLines)
            : next;
      });
      ref.onDispose(sub.cancel);
    }
    return const [];
  }
}
