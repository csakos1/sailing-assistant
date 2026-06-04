import 'dart:async';

import 'package:phone/app/gnss_clock.dart';
import 'package:phone/app/true_time.dart';

/// A true-time anchor imperatív héja: monoton `Stopwatch` + re-anchor timer
/// (ADR 0012).
///
/// A tiszta logika a `resolveAnchor`/`extrapolate` (true_time.dart); ez csak a
/// mellékhatásokat köti össze: GNSS-fix kérés, anchor-csere + Stopwatch-reset,
/// és a következő kísérlet ütemezése. A UI-oldalon a `trueTimeProvider`
/// használja; a háttér-engine service-izolátuma közvetlenül konstruálja
/// (Riverpod nélkül, ADR 0017 A14).
class TrueTimeManager {
  /// Létrehozza a managert a [gnssClock] fix-forrással és a [wallClock]
  /// fallback-órával. A ciklust a [start] indítja.
  TrueTimeManager({required this.gnssClock, required this.wallClock});

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

  /// Leállítja a ciklust (a UI-oldalon a `ref.onDispose`, az engine-oldalon az
  /// `onDestroy` hívja).
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
