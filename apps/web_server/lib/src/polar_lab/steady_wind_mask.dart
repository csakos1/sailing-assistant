import 'package:domain/domain.dart';
import 'package:web_server/src/polar_lab/twa_window_extremes.dart';

/// Az állandósult szelű minták maszkja (ADR 0058 D6): `true`, ha a minta
/// ±[halfWindowSeconds] másodperces környezetében a `|TWA|` terjedelme
/// (max − min, [twaWindowExtremes]) a [maximumRangeDegrees] alatt van.
///
/// Forduláskor, halzoláskor és széllökés-fordulóban a vízsebesség nem a
/// pillanatnyi szélhez tartozik, ezért ezek a minták nem polár-minták. Az
/// ablak a telefonnál kb. 21, a régi naplónál kb. 3 mintát fog át. A szög a
/// `|TWA|`-ból számol (0–180°), így a ±180° körüli előjelváltás hátszélben
/// nem számít fordulónak.
///
/// Az érvénytelen szögű minta (hiányzó vagy nem véges) `true`: azt a közös
/// szűrő úgyis eldobja; a szomszédok közül is csak az érvényesek
/// számítanak. A maszk a `labSamplesOf` `keep`-je, így a minták nem
/// tűnnek el a tüske-szűrő elől (ADR 0058 D1).
///
/// Pure függvény; a [samples] időrendben jön (egy verseny mintái), az
/// eredmény vele egyforma hosszú.
List<bool> steadyWindMask(
  List<PolarSample> samples, {
  int halfWindowSeconds = 10,
  double maximumRangeDegrees = 12,
}) {
  final extremes = twaWindowExtremes(
    samples,
    halfWindowSeconds: halfWindowSeconds,
    measure: _unchanged,
  );
  return [
    for (final window in extremes)
      window == null || window.maximum - window.minimum < maximumRangeDegrees,
  ];
}

double _unchanged(double foldedDegrees) => foldedDegrees;
