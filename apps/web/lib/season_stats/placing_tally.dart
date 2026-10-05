import 'package:flutter/foundation.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy helyezés-kategória (osztály, abszolút vagy egytestű) összesítése
/// egy időszakra (ADR 0049 D3, Addendum 1 P2).
@immutable
class PlacingTally {
  /// Összesítés a megadott darabszámokkal.
  const PlacingTally({
    required this.firsts,
    required this.seconds,
    required this.thirds,
    required this.dnfs,
    required this.dsqs,
    required this.enteredCount,
    required this.finishCount,
    required this.placeSum,
  });

  /// Hány 1. hely.
  final int firsts;

  /// Hány 2. hely.
  final int seconds;

  /// Hány 3. hely.
  final int thirds;

  /// Hány feladás.
  final int dnfs;

  /// Hány kizárás.
  final int dsqs;

  /// Hány versenyen van megadva helyezés (DNF és DSQ is).
  final int enteredCount;

  /// Hány számszerű helyezés (`FinishPlace`) van.
  final int finishCount;

  /// A számszerű helyezések összege.
  final int placeSum;

  /// A dobogók: az 1–3. helyek összege.
  int get podiums => firsts + seconds + thirds;

  /// A számszerű helyezések átlaga; `null`, ha nincs ilyen.
  double? get averagePlace => finishCount == 0 ? null : placeSum / finishCount;
}

/// A [placings] helyezések összesítése; a `null` a meg nem adott
/// helyezés, és nem számít bele semmibe.
PlacingTally tallyPlacings(Iterable<Placing?> placings) {
  var firsts = 0;
  var seconds = 0;
  var thirds = 0;
  var dnfs = 0;
  var dsqs = 0;
  var enteredCount = 0;
  var finishCount = 0;
  var placeSum = 0;
  for (final placing in placings) {
    if (placing == null) continue;
    enteredCount++;
    switch (placing) {
      case FinishPlace(:final place):
        finishCount++;
        placeSum += place;
        if (place == 1) firsts++;
        if (place == 2) seconds++;
        if (place == 3) thirds++;
      case Dnf():
        dnfs++;
      case Dsq():
        dsqs++;
    }
  }
  return PlacingTally(
    firsts: firsts,
    seconds: seconds,
    thirds: thirds,
    dnfs: dnfs,
    dsqs: dsqs,
    enteredCount: enteredCount,
    finishCount: finishCount,
    placeSum: placeSum,
  );
}
