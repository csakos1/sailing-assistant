import 'package:flutter/foundation.dart';
import 'package:foretack_web/season_stats/medal.dart';
import 'package:foretack_web/season_stats/placing_order.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés-kategória (osztály vagy összevont abszolút) összesítése
/// egy időszakra (ADR 0049 Addendum 2 R2, R5).
@immutable
class PlacingTally {
  /// Összesítés a dobogós darabszámokkal és a többi helyezéssel.
  const PlacingTally({
    required this.firsts,
    required this.seconds,
    required this.thirds,
    required this.offPodium,
  });

  /// Hány 1. hely.
  final int firsts;

  /// Hány 2. hely.
  final int seconds;

  /// Hány 3. hely.
  final int thirds;

  /// A dobogón kívüli helyezések: a számok növekvő sorrendben, utánuk a
  /// DNF-ek, majd a DSQ-k.
  final List<Placing> offPodium;

  /// A dobogós helyezések száma.
  int get podiums => firsts + seconds + thirds;

  /// A [medal] érmek száma.
  int countOf(Medal medal) => switch (medal) {
    Medal.gold => firsts,
    Medal.silver => seconds,
    Medal.bronze => thirds,
  };
}

/// A [placings] helyezések összesítése; a `null` a meg nem adott
/// helyezés, és kimarad.
PlacingTally tallyPlacings(Iterable<Placing?> placings) {
  var firsts = 0;
  var seconds = 0;
  var thirds = 0;
  final offPodium = <Placing>[];
  for (final placing in placings) {
    if (placing == null) continue;
    switch (Medal.of(placing)) {
      case Medal.gold:
        firsts++;
      case Medal.silver:
        seconds++;
      case Medal.bronze:
        thirds++;
      case null:
        offPodium.add(placing);
    }
  }
  offPodium.sort((a, b) => placingOrder(a).compareTo(placingOrder(b)));
  return PlacingTally(
    firsts: firsts,
    seconds: seconds,
    thirds: thirds,
    offPodium: List.unmodifiable(offPodium),
  );
}
