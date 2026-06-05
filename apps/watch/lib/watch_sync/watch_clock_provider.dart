import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';
import 'package:watch/watch_sync/watch_clock.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

/// A megjelenített GPS-óra 1 Hz-es olvasat-streamje (ADR 0012 watch-oldal).
///
/// A telefon a payloadban kész true-time-ot küld, de az csak change-detectre
/// érkezik — két küldés közt a másodperc nem frissülne. Ezért a [WatchClock] a
/// legutóbbi megbízható `gpsTimeUtc`-t lokálisan, monoton görgeti, és 1 Hz-en
/// emittáljuk; friss payloadra azonnal is, hogy ne legyen ~1 mp lag.
/// Keep-alive (nem autoDispose): a primary kijelző végig figyel (ADR 0016).
final watchClockProvider = StreamProvider<GpsClockReading>((ref) {
  final clock = WatchClock();
  final controller = StreamController<GpsClockReading>();

  void emit() => controller.add(clock.read());

  // A payload frissíti az anchort; a friss true-time-ra azonnal emittálunk.
  ref.listen<AsyncValue<WatchPayload>>(watchStateProvider, (_, next) {
    next.whenData((payload) {
      clock.onPayload(payload);
      emit();
    });
  }, fireImmediately: true);

  emit(); // kezdeti olvasat — anchor híján untrusted (azonnali `--:--:--`)
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => emit());

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
