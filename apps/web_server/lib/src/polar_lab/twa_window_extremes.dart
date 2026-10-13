import 'package:domain/domain.dart';

/// A legkisebb és a legnagyobb mért érték egy minta ablakában.
typedef WindowExtremes = ({double minimum, double maximum});

/// Minden minta köré igazított ±[halfWindowSeconds] másodperces ablakban a
/// `|TWA|`-ból számolt érték ([measure]) legkisebb és legnagyobb értéke
/// (ADR 0058 D6).
///
/// A [measure] a fél-rács 0–180°-ára hajtott szöget kapja
/// ([foldedTwaDegrees]), így a ±180° körüli előjelváltás hátszélben nem
/// számít mozgásnak. Az ablakban csak az érvényes szögek számítanak; az
/// érvénytelen saját szögű minta eredménye `null`.
///
/// Pure függvény; a [samples] időrendben jön (egy verseny mintái), a
/// [halfWindowSeconds] nem negatív, az eredmény vele egyforma hosszú.
List<WindowExtremes?> twaWindowExtremes(
  List<PolarSample> samples, {
  required int halfWindowSeconds,
  required double Function(double foldedDegrees) measure,
}) {
  if (halfWindowSeconds < 0) {
    throw ArgumentError.value(
      halfWindowSeconds,
      'halfWindowSeconds',
      'must not be negative',
    );
  }
  final halfWindow = Duration(seconds: halfWindowSeconds);
  final extremes = <WindowExtremes?>[];
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
    extremes.add(
      foldedTwaDegrees(sample.twaDeg) == null
          ? null
          : _extremesOf(samples.sublist(low, high + 1), measure),
    );
  }
  return extremes;
}

/// Az előjeles szög a fél-rács 0–180°-ára, ahogy a `labSamplesOf`-ban; a
/// hiányzó vagy nem véges szög `null`.
double? foldedTwaDegrees(double? twaDeg) {
  if (twaDeg == null || !twaDeg.isFinite) return null;
  final normalized = twaDeg % 360;
  return normalized > 180 ? 360 - normalized : normalized;
}

// Az ablak érvényes szögeinek szélsőértékei. Az ablak sosem üres érvényes
// szögben: a minta saját szöge benne van.
WindowExtremes _extremesOf(
  List<PolarSample> window,
  double Function(double foldedDegrees) measure,
) {
  var minimum = double.infinity;
  var maximum = double.negativeInfinity;
  for (final neighbour in window) {
    final angle = foldedTwaDegrees(neighbour.twaDeg);
    if (angle == null) continue;
    final value = measure(angle);
    if (value < minimum) minimum = value;
    if (value > maximum) maximum = value;
  }
  return (minimum: minimum, maximum: maximum);
}
