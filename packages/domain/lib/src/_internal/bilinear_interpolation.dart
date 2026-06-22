/// Bilineáris interpoláció egy rács-cellán belül, hiányzó (üres) sarkok
/// kezelésével.
///
/// Library-internal helper (nincs a `domain.dart` barrel-ben). A
/// `LookupTargetSpeed` use case használja: az megkeresi a TWA×TWS rácson
/// a bracketelő cellát és a cellán belüli frakciókat, ez a függvény pedig
/// elvégzi a numerikus interpolációt. Külön top-level függvény, hogy a
/// use case mock-olása nélkül unit-tesztelhető legyen (mint a
/// `linearRegression` / `unwrapAngles`).
///
/// A négy sarok a cella (alacsony/magas TWA) × (alacsony/magas TWS)
/// rács-értéke; bármelyik `null` lehet (üres vödör). A `twaFraction` és a
/// `twsFraction` a cellán belüli pozíció 0–1 között.
///
/// **Hiányzó sarkok.** Ha mind a négy sarok adott, ez pontos bilineáris
/// interpoláció (a súlyok 1-re összegződnek). Ha 1–3 sarok `null`, a
/// meglévő sarkokra súly-újranormálással átlagolunk (a hiányzókat
/// kihagyjuk). Ha mind a négy `null` — vagy a nem-null sarkok együttes
/// súlya 0, mert a tényleges vödör üres —, az eredmény `null`.
double? bilinearInterpolate({
  required double? lowTwaLowTws,
  required double? lowTwaHighTws,
  required double? highTwaLowTws,
  required double? highTwaHighTws,
  required double twaFraction,
  required double twsFraction,
}) {
  final lowTwaWeight = 1 - twaFraction;
  final lowTwsWeight = 1 - twsFraction;

  var weightedSum = 0.0;
  var weightTotal = 0.0;

  // Csak a nem-null sarkok járulnak hozzá; a hiányzók kihagyásával a
  // megmaradó súlyokra implicit újranormálunk (weightedSum / weightTotal).
  void accumulate(double? value, double weight) {
    if (value == null) return;
    weightedSum += value * weight;
    weightTotal += weight;
  }

  accumulate(lowTwaLowTws, lowTwaWeight * lowTwsWeight);
  accumulate(lowTwaHighTws, lowTwaWeight * twsFraction);
  accumulate(highTwaLowTws, twaFraction * lowTwsWeight);
  accumulate(highTwaHighTws, twaFraction * twsFraction);

  if (weightTotal == 0) return null;
  return weightedSum / weightTotal;
}
