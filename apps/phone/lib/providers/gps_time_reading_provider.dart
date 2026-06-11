import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/true_time_provider.dart';

/// A GPS-idő cellának másodperc-határra igazított olvasat-streamje (ADR 0012 +
/// Addendum 1 D-b).
///
/// A `trueTimeProvider` kész `TrueTimeReading`-et ad, de a generikus
/// `tickProvider` szabad fázisú — a számjegy 0–1 mp-cel a valódi
/// másodperc-határ után váltana. Ezért a cella ezt a dedikált streamet
/// fogyasztja: egy láncolt, önkorrigáló `Timer` a becsült óra következő
/// másodperc-határán emittál (`millisToNextSecond`), így a számjegy a valódi
/// határon vált és a jitter nem halmozódik. A `tickProvider` érintetlen (az a
/// compute-kadencia, SRP). Keep-alive: a live screen életében végig figyel.
final gpsTimeReadingProvider = StreamProvider<TrueTimeReading>((ref) {
  final readTrueTime = ref.watch(trueTimeProvider);
  final controller = StreamController<TrueTimeReading>();
  Timer? timer;
  var closed = false;

  void emit() {
    if (!closed) {
      controller.add(readTrueTime());
    }
  }

  void scheduleNext() {
    if (closed) {
      return;
    }
    final delay = Duration(
      milliseconds: millisToNextSecond(readTrueTime().utc),
    );
    timer = Timer(delay, () {
      emit();
      scheduleNext();
    });
  }

  emit(); // azonnali kezdeti olvasat
  scheduleNext();

  ref.onDispose(() {
    closed = true;
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});
