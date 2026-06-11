import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/watch_clock.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

/// A megjelenített GPS-óra másodperc-határra igazított olvasat-streamje (ADR
/// 0012 watch-oldal + Addendum 1 D-b).
///
/// A telefon a payloadban kész true-time-ot küld, de az csak change-detectre
/// érkezik — két küldés közt a másodperc nem frissülne. Ezért a [WatchClock] a
/// legutóbbi megbízható `gpsTimeUtc`-t lokálisan, monoton görgeti, és egy
/// láncolt `Timer` a becsült óra **következő másodperc-határán** emittál
/// (`millisToNextSecond`), így a számjegy a valódi határon vált és a jitter nem
/// halmozódik; friss payloadra azonnal is, hogy ne legyen ~1 mp lag. Keep-alive
/// (nem autoDispose): a primary kijelző végig figyel (ADR 0016).
final watchClockProvider = StreamProvider<GpsClockReading>((ref) {
  final clock = WatchClock();
  final controller = StreamController<GpsClockReading>();
  Timer? timer;
  var closed = false;

  void emit() {
    if (!closed) {
      controller.add(clock.read());
    }
  }

  // Láncolt, önkorrigáló tick: minden ütem frissen a következő
  // másodperc-határig ütemez (Addendum 1 D-b).
  void scheduleNext() {
    if (closed) {
      return;
    }
    final delay = Duration(
      milliseconds: millisToNextSecond(clock.read().displayUtc),
    );
    timer = Timer(delay, () {
      emit();
      scheduleNext();
    });
  }

  // A payload frissíti az anchort; azonnal emittálunk, és újraütemezünk, hogy a
  // tick a frissített órához igazodjon.
  ref.listen<AsyncValue<WatchPayload>>(watchStateProvider, (_, next) {
    next.whenData((payload) {
      clock.onPayload(payload);
      emit();
      timer?.cancel();
      scheduleNext();
    });
  }, fireImmediately: true);

  emit(); // kezdeti olvasat — anchor híján untrusted (azonnali `--:--:--`)
  scheduleNext();

  ref.onDispose(() {
    closed = true;
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
