import 'package:race_archive_api/race_archive_api.dart';

// A DNF és a DSQ minden számszerű helyezés mögé kerül, a DSQ a DNF mögé
// (ADR 0049 Addendum 2 R1).
const int _dnfOrder = 1 << 30;
const int _dsqOrder = _dnfOrder + 1;

/// A [placing] sorrendi kulcsa: a kisebb a jobb helyezés.
int placingOrder(Placing placing) => switch (placing) {
  FinishPlace(:final place) => place,
  Dnf() => _dnfOrder,
  Dsq() => _dsqOrder,
};

/// A [first] és a [second] helyezés jobbika; a hiányzó a másikat adja.
///
/// Az összevont abszolút helyezés szabálya (R1): két számból a kisebb,
/// szám és DNF/DSQ közül a szám, DNF és DSQ közül a DNF.
Placing? betterPlacing(Placing? first, Placing? second) {
  if (first == null) return second;
  if (second == null) return first;
  return placingOrder(second) < placingOrder(first) ? second : first;
}
