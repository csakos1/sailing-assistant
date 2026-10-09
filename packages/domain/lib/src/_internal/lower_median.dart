/// Library-internal helper: egy nem üres lista alsó mediánja (ADR 0048
/// Addendum 5 L3, ADR 0049 D13).
///
/// Páros elemszámnál a két középső közül a kisebb: a tüske-szűrés célja
/// miatt a kisebbik érték a biztonságosabb. A bemenetet nem módosítja.
///
/// Az ablakok kicsik (5 elem), ezért a rendezés költsége elhanyagolható;
/// egy rendezett csúszó struktúra itt csak bonyolítana.
double lowerMedian(List<double> values) {
  assert(values.isNotEmpty, 'Üres lista mediánja nem értelmezett.');
  final sorted = [...values]..sort();
  return sorted[(sorted.length - 1) ~/ 2];
}
