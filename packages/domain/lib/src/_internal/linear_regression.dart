/// Library-internal helper: egyszerű (OLS) lineáris regresszió
/// `(x, y)` pontpárokra. Records-ban adja vissza a slope-ot és az r²
/// érték-arányt; az intercept-et NEM, mert a 7.4 use case
/// (ARCHITECTURE.md) nem használja — a `WindShiftTrend.currentTwd`-t
/// az unwrap-elt sorozat utolsó eleméből nyeri, nem a regresszió
/// Y-tengely-metszetéből.
///
/// **Numerikusan stabil két-pass implementáció.** Az első pass
/// kiszámolja a mean-eket, a második a centered szumákat
/// (`Σ((x-meanX)(y-meanY))`, `Σ(x-meanX)²`, `Σ(y-meanY)²`). Ez azért
/// kritikus, mert a 7.4 use case `x = millisecondsSinceEpoch / 60000`
/// formában küldi az időt — ~2.9e7 nagyságrendű érték —, és a naív
/// `(n·Σx² − (Σx)²)` osztó IEEE 754 double mantissza-precízión
/// (~4.5e15) catastrophic cancellation-t szenvedne 600 mintás ablakon.
/// A centered formulák `sxy/sxx` és `sxy²/(sxx·syy)` ezt elkerülik.
///
/// **Edge case-ek — NaN-tuple visszatérés:**
/// - üres input (`n == 0`)
/// - egyetlen pont (`n == 1`)
/// - konstans `x` (`sxx == 0`): vertikális illesztés, slope nem
///   definiált
/// - konstans `y` (`syy == 0`): nincs varianca, r² formálisan 0/0;
///   a slope ugyan érvényesen 0, de a teljes tuple NaN-os, hogy a
///   hívó (7.4) egyszerű `.isFinite` szűrése elkapja
///
/// **Hard fail — [ArgumentError]:**
/// - `x.length != y.length` — programozói hiba, nem futáskori adat-
///   probléma. A 7.4 use case egyazon `recent` listából map-eli ki
///   mindkettőt, így ez sosem áll elő production útvonalon.
///
/// **NaN / ±infinity input.** Library-internal kontraktban a hívó
/// felelős. NaN/±inf esetén a mean-ek és a centered szumák
/// propagálódnak NaN-osan; az `sxx == 0` és `syy == 0` guard-feltételek
/// NaN-t NEM kapnak el (NaN != 0), így a return de facto (NaN, NaN)
/// lesz — működő, de nem formálisan garantált viselkedés.
(double slope, double rSquared) linearRegression(
  List<double> x,
  List<double> y,
) {
  if (x.length != y.length) {
    throw ArgumentError(
      'x és y azonos hosszúságú kell legyen '
      '(x: ${x.length}, y: ${y.length}).',
    );
  }

  final n = x.length;
  if (n < 2) {
    return (double.nan, double.nan);
  }

  // Pass 1: mean-ek számolása
  var sumX = 0.0;
  var sumY = 0.0;
  for (var i = 0; i < n; i++) {
    sumX += x[i];
    sumY += y[i];
  }
  final meanX = sumX / n;
  final meanY = sumY / n;

  // Pass 2: centered szumák
  var sxy = 0.0;
  var sxx = 0.0;
  var syy = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = x[i] - meanX;
    final dy = y[i] - meanY;
    sxy += dx * dy;
    sxx += dx * dx;
    syy += dy * dy;
  }

  if (sxx == 0) {
    // Konstans x: vertikális illesztés, slope nem definiált.
    return (double.nan, double.nan);
  }
  if (syy == 0) {
    // Konstans y: nincs varianca, r² 0/0 formátumú lenne.
    return (double.nan, double.nan);
  }

  final slope = sxy / sxx;
  final rSquared = (sxy * sxy) / (sxx * syy);
  return (slope, rSquared);
}
