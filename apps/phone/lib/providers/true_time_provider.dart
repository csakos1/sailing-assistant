import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/gnss_clock.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/gnss_clock_provider.dart';

/// A true-time forrást adó keep-alive provider (ADR 0012).
///
/// Egy `TrueTimeReading Function()` callable-t ad (a `clockProvider`-seam
/// mintájára), amit a GPS-cella az 1 Hz tick-en hív. A belső
/// `_TrueTimeManager` tartja a GNSS-anchort + a monoton `Stopwatch`-ot, és
/// időnként re-anchorol (cold-start 20 mp, steady 2 perc). Keep-alive, hogy az
/// anchor a live screen re-mountját is túlélje; a `ref.onDispose` állítja le a
/// timert. Tesztben a `gnssClockProvider` / `clockProvider` override-olható.
final trueTimeProvider = Provider<TrueTimeReading Function()>((ref) {
  final manager = _TrueTimeManager(
    gnssClock: ref.watch(gnssClockProvider),
    wallClock: ref.watch(clockProvider),
  )..start();
  ref.onDispose(manager.dispose);
  return manager.read;
});

/// A true-time anchor imperatív héja: monoton `Stopwatch` + re-anchor timer.
///
/// A tiszta logika a `resolveAnchor`/`extrapolate` (true_time.dart); ez csak a
/// mellékhatásokat köti össze: GNSS-fix kérés, anchor-csere + Stopwatch-reset,
/// és a következő kísérlet ütemezése.
class _TrueTimeManager {
  _TrueTimeManager({required this.gnssClock, required this.wallClock});

  /// A GNSS-óra (fake-elhető a tesztben).
  final GnssClock gnssClock;

  /// A telefon wall-clock-ja (fallbackhez; `clockProvider`-seam).
  final DateTime Function() wallClock;

  // Cold-start: gyakori próba az első fixig; utána ritka steady re-anchor.
  static const Duration _coldRetryInterval = Duration(seconds: 20);
  static const Duration _steadyInterval = Duration(minutes: 2);

  final Stopwatch _monotonic = Stopwatch();
  TrueTimeAnchor? _anchor;
  Timer? _timer;
  bool _disposed = false;

  /// Elindítja az első fix-kísérletet és a re-anchor ciklust.
  void start() => unawaited(_attemptAnchor());

  /// A pillanatnyi olvasat: az anchor extrapolálva a monoton eltelt idővel.
  TrueTimeReading read() {
    final anchor = _anchor;
    if (anchor == null) {
      return const TrueTimeReading(utc: null, source: TrueTimeSource.none);
    }
    return anchor.readingAfter(_monotonic.elapsed);
  }

  /// Leállítja a ciklust (a `ref.onDispose` hívja).
  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }

  Future<void> _attemptAnchor() async {
    final fixUtc = await gnssClock();
    if (_disposed) {
      return;
    }
    final previous = _anchor;
    final next = resolveAnchor(
      fixUtc: fixUtc,
      wallClockUtc: wallClock().toUtc(),
      current: previous,
    );
    // Új rögzítési instant → a monoton órát az anchorhoz nullázzuk; ha az
    // anchorUtc nem változott (sessionAnchor), tovább fut az eltelt idő.
    if (previous == null || next.anchorUtc != previous.anchorUtc) {
      _monotonic
        ..reset()
        ..start();
    }
    _anchor = next;
    _scheduleNext();
  }

  void _scheduleNext() {
    // Amíg sosem volt GNSS-fix → gyakori retry; utána steady re-anchor.
    final hadGnss =
        _anchor?.source == TrueTimeSource.gnss ||
        _anchor?.source == TrueTimeSource.sessionAnchor;
    _timer = Timer(
      hadGnss ? _steadyInterval : _coldRetryInterval,
      () => unawaited(_attemptAnchor()),
    );
  }
}
