import 'dart:async';

import 'package:phone/app/gnss_clock.dart';
import 'package:phone/app/true_time.dart';

/// A true-time anchor imperatív héja: monoton `Stopwatch` + re-anchor timer
/// (ADR 0012 + Addendum 1).
///
/// A tiszta logika a `resolveAnchor`/`extrapolate`/`selectBestAnchorUtc`
/// (true_time.dart); ez csak a mellékhatásokat köti össze: GNSS-fix-burst a
/// stream-seamen, a min-késésű minta kiválasztása, anchor-csere +
/// Stopwatch-reset, és a következő kísérlet ütemezése. A UI-oldalon a
/// `trueTimeProvider` használja; a háttér-engine service-izolátuma közvetlenül
/// konstruálja (Riverpod nélkül, ADR 0017 A14).
class TrueTimeManager {
  /// Létrehozza a managert a [gnssClock] fix-stream-forrással és a [wallClock]
  /// fallback-órával. A ciklust a [start] indítja.
  TrueTimeManager({required this.gnssClock, required this.wallClock});

  /// A GNSS-óra fix-stream-seamje (fake-elhető a tesztben).
  final GnssClock gnssClock;

  /// A telefon wall-clock-ja (fallbackhez; `clockProvider`-seam).
  final DateTime Function() wallClock;

  // Cold-start: gyakori próba az első fixig; utána ritka steady re-anchor.
  static const Duration _coldRetryInterval = Duration(seconds: 20);
  static const Duration _steadyInterval = Duration(minutes: 2);

  // Re-anchor stream-burst (Addendum 1 D-a): legfeljebb ennyi mintáig vagy a
  // timeoutig gyűjtünk, aztán zárjuk a streamet (D4: nem folyamatos GPS).
  static const int _burstMaxSamples = 5;
  static const Duration _burstTimeout = Duration(seconds: 6);

  final Stopwatch _monotonic = Stopwatch();
  TrueTimeAnchor? _anchor;
  Timer? _timer;
  StreamSubscription<DateTime>? _burstSub;
  Timer? _burstCap;
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

  /// Leállítja a ciklust + a futó burstöt (a UI-oldalon a `ref.onDispose`, az
  /// engine-oldalon az `onDestroy` hívja).
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _burstCap?.cancel();
    unawaited(_burstSub?.cancel());
  }

  Future<void> _attemptAnchor() async {
    final fixUtc = await _burstBestFixUtc();
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
    // anchorUtc nem változott (sessionAnchor), tovább fut az eltelt idő. A
    // fixUtc itt már a burst-végre vetített, min-késésű horgony (Addendum 1).
    if (previous == null || next.anchorUtc != previous.anchorUtc) {
      _monotonic
        ..reset()
        ..start();
    }
    _anchor = next;
    _scheduleNext();
  }

  // Rövid fix-burst: minden mintát a beérkezésekor egy burst-lokális monoton
  // órával párosít, majd a pure selectBestAnchorUtc a min-késésűt választja.
  // Üres burst (GPS ki / engedély megtagadva / timeout) → null, a D6
  // fallback-lánc dönt. A streamet a feliratkozás megszüntetése zárja.
  Future<DateTime?> _burstBestFixUtc() async {
    final samples = <GnssSample>[];
    final burst = Stopwatch()..start();
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    _burstSub = gnssClock().listen(
      (fixUtc) {
        samples.add((fixUtc: fixUtc, sampleElapsed: burst.elapsed));
        if (samples.length >= _burstMaxSamples) {
          finish();
        }
      },
      onError: (_, _) => finish(),
      onDone: finish,
    );
    _burstCap = Timer(_burstTimeout, finish);

    await done.future;
    await _burstSub?.cancel();
    _burstSub = null;
    _burstCap?.cancel();
    _burstCap = null;

    if (samples.isEmpty) {
      return null;
    }
    return selectBestAnchorUtc(samples, burst.elapsed);
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
