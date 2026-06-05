import 'package:shared/shared.dart';
import 'package:watch/watch_sync/gps_clock_reading.dart';

/// Monoton eltelt-idő forrás (seam a tesztelhetőségért): egy közös origótól
/// eltelt idő. Éles esetben egy indított `Stopwatch`, tesztben fake függvény —
/// így a [WatchClock] extrapolációja determinisztikusan verifikálható (a
/// telefon `clockProvider` / `GnssClock` függvény-seam mintájára).
typedef MonotonicSource = Duration Function();

/// Az óra-lokális GPS-óra imperatív héja (ADR 0012 watch-oldal, D3).
///
/// A legutóbbi megbízható payload `gpsTimeUtc`-jét rögzíti anchorként, és a
/// [MonotonicSource] eltelt idejével extrapolálja előre — NEM a wall-clock
/// különbséggel, így immunis az óra fali-órájának ugrásaira. Nem megbízható
/// (vagy hiányzó `gpsTimeUtc`-jű) payload törli az anchort. Tiszta,
/// Riverpod-mentes osztály — közvetlenül unit-tesztelhető.
class WatchClock {
  /// Létrehozza az órát; a [monotonic] alapból egy frissen indított
  /// `Stopwatch`-ra épül, tesztben fake-elhető.
  WatchClock({MonotonicSource? monotonic})
    : _monotonic = monotonic ?? _startedStopwatch();

  final MonotonicSource _monotonic;

  DateTime? _anchorUtc;
  Duration? _anchorElapsed;

  static MonotonicSource _startedStopwatch() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  /// Feldolgoz egy beérkező [payload]-ot: megbízható, nem-null `gpsTimeUtc`
  /// esetén új anchort rögzít (és nullázza az eltelt-idő origót); különben
  /// törli az anchort (→ untrusted olvasat).
  void onPayload(WatchPayload payload) {
    final gpsTimeUtc = payload.gpsTimeUtc;
    if (payload.isGpsTimeTrusted && gpsTimeUtc != null) {
      _anchorUtc = gpsTimeUtc;
      _anchorElapsed = _monotonic();
    } else {
      _anchorUtc = null;
      _anchorElapsed = null;
    }
  }

  /// A pillanatnyi olvasat: az anchor a horgony óta eltelt monoton idővel
  /// extrapolálva, vagy untrusted, ha nincs anchor.
  GpsClockReading read() {
    final anchorUtc = _anchorUtc;
    final anchorElapsed = _anchorElapsed;
    if (anchorUtc == null || anchorElapsed == null) {
      return const GpsClockReading.untrusted();
    }
    final elapsed = _monotonic() - anchorElapsed;
    return GpsClockReading(displayUtc: anchorUtc.add(elapsed), isTrusted: true);
  }
}
