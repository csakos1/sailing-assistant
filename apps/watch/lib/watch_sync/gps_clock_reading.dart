import 'package:flutter/foundation.dart';

/// Az órán megjelenített GPS-óra pillanatnyi olvasata (ADR 0012 watch-oldal).
///
/// A telefon kész true-time-ot küld a payloadban; az óra ezt lokálisan,
/// monoton görgeti. A [displayUtc] a kijelzendő UTC (a hívó `toLocal()`-lal
/// rendereli), az [isTrusted] a pötty színét vezérli (megbízható → teal,
/// különben tompított + `--:--:--`).
@immutable
class GpsClockReading {
  /// Olvasat a [displayUtc] kijelzendő UTC-vel és az [isTrusted] flaggel.
  const GpsClockReading({required this.displayUtc, required this.isTrusted});

  /// Nincs megbízható idő: `displayUtc == null`, `isTrusted == false`.
  const GpsClockReading.untrusted() : displayUtc = null, isTrusted = false;

  /// A kijelzendő UTC, vagy `null`, ha nincs megbízható idő.
  final DateTime? displayUtc;

  /// Megbízható-e a kijelzett idő (a payload `isGpsTimeTrusted`-jéből).
  final bool isTrusted;

  @override
  bool operator ==(Object other) =>
      other is GpsClockReading &&
      other.displayUtc == displayUtc &&
      other.isTrusted == isTrusted;

  @override
  int get hashCode => Object.hash(displayUtc, isTrusted);
}
