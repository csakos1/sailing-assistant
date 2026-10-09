import 'dart:collection';

import 'package:web_server/src/auth/utc_now.dart';

// Ennyi kulcs fölött a régi kulcsok kitakarítódnak (ablakonként legfeljebb
// egyszer), hogy a sok különböző IP ne növelje korlátlanul a memóriát, és
// a takarítás se fusson minden hívásnál.
const int _sweepThreshold = 4096;

/// Csúszó ablakos próbálkozás-korlát a memóriában (ADR 0051 D8,
/// Addendum 3 K8).
///
/// Kulcsonként (pl. IP-nként) legfeljebb [limit] próbálkozás egy [window]
/// ablakban. A szerver egy példányban fut, ezért elég a memória; egy
/// újraindítás a számlálókat nullázza, ami elfogadható.
final class RateLimiter {
  /// Korlát: [limit] próbálkozás [window] alatt, a [now] órával.
  RateLimiter({
    required this.limit,
    required this.window,
    DateTime Function() now = utcNow,
  }) : _now = now;

  /// A próbálkozások legnagyobb száma az ablakban.
  final int limit;

  /// Az ablak hossza.
  final Duration window;

  final DateTime Function() _now;
  final Map<String, ListQueue<DateTime>> _attempts = {};
  DateTime? _lastSweep;

  /// Egy próbálkozás a [key] kulcson: `null`, ha belefér (és beszámít);
  /// különben a várakozás, amely után újra lehet.
  Duration? tryAcquire(String key) {
    final now = _now();
    final cutoff = now.subtract(window);
    final lastSweep = _lastSweep;
    final isSweepDue = lastSweep == null || !lastSweep.isAfter(cutoff);
    if (_attempts.length > _sweepThreshold && isSweepDue) {
      _sweep(cutoff);
      _lastSweep = now;
    }
    final attempts = _attempts.putIfAbsent(key, ListQueue.new);
    _dropOlderThan(attempts, cutoff);
    if (attempts.length >= limit) {
      return attempts.first.add(window).difference(now);
    }
    attempts.addLast(now);
    return null;
  }

  void _sweep(DateTime cutoff) {
    _attempts.removeWhere((_, attempts) {
      _dropOlderThan(attempts, cutoff);
      return attempts.isEmpty;
    });
  }

  static void _dropOlderThan(ListQueue<DateTime> attempts, DateTime cutoff) {
    while (attempts.isNotEmpty && !attempts.first.isAfter(cutoff)) {
      attempts.removeFirst();
    }
  }
}
