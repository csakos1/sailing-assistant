import 'dart:math' as math;

import 'package:web_server/src/auth/utc_now.dart';

/// Ennyi egymást követő hibás tartalék-belépés után kezdődik a várakozás
/// (ADR 0051 D8).
const int fallbackFailuresBeforeBackoff = 5;

/// A várakozás felső korlátja.
const Duration maximumFallbackBackoff = Duration(hours: 1);

// Ha egy próbálkozás csak azért nem indulhat, mert a többi még fut, ennyi
// múlva érdemes újra próbálni.
const Duration _busyWait = Duration(seconds: 1);

/// A tartalék belépés fiók-szintű várakozása (ADR 0051 D8, Addendum 6 N3).
///
/// Egy `owner` van, ezért egyetlen számláló: az 5. egymást követő hiba
/// után 1 perc, utána minden újabb hibánál kétszeres, legfeljebb 1 óra. Egy
/// sikeres belépés nullázza. Memóriában él, a szerver újraindítása
/// nullázza (D8).
///
/// A próbálkozást az ellenőrzés **előtt** le kell foglalni ([tryBegin]):
/// így párhuzamos kérésekkel sem futhat több próbálkozás, mint amennyit a
/// számláló enged, és a várakozás után egyszerre csak egy.
final class FallbackBackoff {
  /// Várakozás a [now] óra szerint.
  FallbackBackoff({DateTime Function() now = utcNow}) : _now = now;

  final DateTime Function() _now;
  int _failures = 0;
  int _inFlight = 0;
  DateTime? _blockedUntil;

  /// A hátralévő várakozás; `null`, ha a fiók most nincs letiltva.
  Duration? remainingWait() {
    final blockedUntil = _blockedUntil;
    if (blockedUntil == null) return null;
    final remaining = blockedUntil.difference(_now());
    return remaining > Duration.zero ? remaining : null;
  }

  /// Egy próbálkozás lefoglalása: `null`, ha indulhat (utána [end] kötelező);
  /// különben mennyit kell várni.
  Duration? tryBegin() {
    final remaining = remainingWait();
    if (remaining != null) return remaining;
    final isSaturated =
        _inFlight > 0 && _failures + _inFlight >= fallbackFailuresBeforeBackoff;
    if (isSaturated) return _busyWait;
    _inFlight++;
    return null;
  }

  /// A lefoglalt próbálkozás vége: siker nulláz, hiba számít, és az 5.
  /// hibától várakozást indít.
  void end({required bool isSuccess}) {
    _inFlight--;
    if (isSuccess) {
      _failures = 0;
      _blockedUntil = null;
      return;
    }
    _failures++;
    if (_failures < fallbackFailuresBeforeBackoff) return;
    final doublings = _failures - fallbackFailuresBeforeBackoff;
    // 2^6 perc már az 1 óra fölött van; a kitevő korlátja a túlcsordulást
    // is kizárja.
    final wait = Duration(minutes: 1 << math.min(doublings, 6));
    _blockedUntil = _now().add(
      wait > maximumFallbackBackoff ? maximumFallbackBackoff : wait,
    );
  }
}
