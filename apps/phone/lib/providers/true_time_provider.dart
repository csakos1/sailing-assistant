import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/app/true_time_manager.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/gnss_clock_provider.dart';

/// A true-time forrást adó keep-alive provider (ADR 0012).
///
/// Egy `TrueTimeReading Function()` callable-t ad (a `clockProvider`-seam
/// mintájára), amit a GPS-cella az 1 Hz tick-en hív. A belső `TrueTimeManager`
/// tartja a GNSS-anchort + a monoton `Stopwatch`-ot, és időnként re-anchorol
/// (cold-start 20 mp, steady 2 perc). Keep-alive, hogy az anchor a live screen
/// re-mountját is túlélje; a `ref.onDispose` állítja le a timert. Tesztben a
/// `gnssClockProvider` / `clockProvider` override-olható.
final trueTimeProvider = Provider<TrueTimeReading Function()>((ref) {
  final manager = TrueTimeManager(
    gnssClock: ref.watch(gnssClockProvider),
    wallClock: ref.watch(clockProvider),
  )..start();
  ref.onDispose(manager.dispose);
  return manager.read;
});
