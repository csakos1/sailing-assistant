import 'package:domain/domain.dart';

/// Az állandósult szelű minták maszkja (ADR 0058 D6): `true`, ha a minta
/// ±[halfWindowSeconds] másodperces környezetében a `|TWA|` terjedelme
/// (max − min) a [maximumRangeDegrees] alatt van.
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
  if (halfWindowSeconds < 0) {
    throw ArgumentError.value(
      halfWindowSeconds,
      'halfWindowSeconds',
      'must not be negative',
    );
  }
  final halfWindow = Duration(seconds: halfWindowSeconds);
  final mask = <bool>[];
  var low = 0;
  var high = 0;
  for (final (index, sample) in samples.indexed) {
    final earliest = sample.timestamp.subtract(halfWindow);
    final latest = sample.timestamp.add(halfWindow);
    while (samples[low].timestamp.isBefore(earliest)) {
      low++;
    }
    if (high < index) high = index;
    while (high + 1 < samples.length &&
        !samples[high + 1].timestamp.isAfter(latest)) {
      high++;
    }
    mask.add(
      _foldedAngle(sample.twaDeg) == null ||
          _angleRange(samples.sublist(low, high + 1)) < maximumRangeDegrees,
    );
  }
  return mask;
}

// A `|TWA|` terjedelme az ablak érvényes szögein. Az ablak sosem üres
// érvényes szögben: a minta saját szöge benne van.
double _angleRange(List<PolarSample> window) {
  var minimum = double.infinity;
  var maximum = double.negativeInfinity;
  for (final neighbour in window) {
    final angle = _foldedAngle(neighbour.twaDeg);
    if (angle == null) continue;
    if (angle < minimum) minimum = angle;
    if (angle > maximum) maximum = angle;
  }
  return maximum - minimum;
}

// Az előjeles szög a fél-rács 0–180°-ára, ahogy a `labSamplesOf`-ban; az
// érvénytelen szög `null`.
double? _foldedAngle(double? twaDeg) {
  if (twaDeg == null || !twaDeg.isFinite) return null;
  final normalized = twaDeg % 360;
  return normalized > 180 ? 360 - normalized : normalized;
}
