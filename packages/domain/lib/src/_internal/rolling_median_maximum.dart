/// Library-internal helper: egy időrendi sorozat csúszó mediánjainak
/// maximuma (ADR 0048 Addendum 5 L3).
///
/// Egy műszer rövid tüskéjét szűri ki egy maximumból: a [windowSize]
/// széles ablak mediánja egy legfeljebb `windowSize ~/ 2` mintás tüskét
/// nem lát, egy ennél hosszabb szintet viszont megtart. Az 5-ös ablak 1 Hz
/// mellett a ≤ 2 mp-es tüskét dobja ki, a ≥ 3 mp-es lökést megtartja.
///
/// - Üres [values] → `null`.
/// - Ha a [values] rövidebb a [windowSize]-nál, az összes érték egyetlen
///   mediánja az eredmény.
/// - Páros elemszámú ablak (csak a rövid sorozatnál fordul elő) mediánja
///   az alsó középső érték: a tüske-szűrés célja miatt a kisebbik.
///
/// A [values] sorrendje számít (időrend); a függvény nem rendezi át.
///
/// **Hard fail — [ArgumentError]:** páratlan, pozitív [windowSize] kell.
/// A páros ablaknak nincs középső mintája, ez programozói hiba.
double? rollingMedianMaximum(List<double> values, {required int windowSize}) {
  if (windowSize < 1 || windowSize.isEven) {
    throw ArgumentError.value(
      windowSize,
      'windowSize',
      'must be a positive odd number',
    );
  }
  if (values.isEmpty) return null;
  if (values.length <= windowSize) return _lowerMedian(values);

  double? maximum;
  for (var start = 0; start + windowSize <= values.length; start++) {
    final median = _lowerMedian(values.sublist(start, start + windowSize));
    if (maximum == null || median > maximum) maximum = median;
  }
  return maximum;
}

// Az ablak kicsi (5 elem), ezért a rendezés költsége elhanyagolható; egy
// rendezett csúszó struktúra itt csak bonyolítana.
double _lowerMedian(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[(sorted.length - 1) ~/ 2];
}
