import 'dart:math';

/// A VMG (Velocity Made Good) kiszámítása: a hajósebesség szélirányba vett
/// komponense, csomóban. Pozitív érték = szél felé (felmenő, |TWA| < 90°);
/// negatív = széltől elfelé (lemenő, |TWA| > 90°).
///
/// Képlet: VMG = hajósebesség × cos(TWA). Tiszta, totális függvény: minden
/// sebesség- és szögbemenet érvényes (nincs no-go-kapu, mint a
/// `LookupTargetSpeed`-nél). A sebesség-forrás (STW, SOG-fallback) és a
/// null-kezelés a hívó (engine) dolga; itt mindkét bemenet kötelezően nem-null.
final class ComputeVmg {
  /// Const ctor — állapotmentes, újrahasználható use case.
  const ComputeVmg();

  /// A [boatSpeedKnots] szélirányba vett vetülete a [twaDegrees] valódi
  /// szélszögnél, csomóban. A TWA előjele nem számít (a `cos` páros függvény),
  /// így |TWA| és az előjeles TWA ugyanazt az eredményt adja.
  double call({required double boatSpeedKnots, required double twaDegrees}) {
    // A dart:math cos radiánt vár; a TWA a domain-konvenció szerint fokban van.
    final twaRadians = twaDegrees * pi / 180;
    return boatSpeedKnots * cos(twaRadians);
  }
}
