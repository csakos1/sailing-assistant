import 'package:domain/domain.dart';
import 'package:web_server/src/polar_lab/lab_sample.dart';

/// Egy időre súlyozott teljesítmény-érték (%).
typedef WeightedPct = ({double pct, int seconds});

/// Egy minta teljesítménye a [polar]-hoz: `100 × STW / cél-STW`, ugyanazzal
/// a lookuppal, mint a weben (ADR 0049 D5). `null`, ha nincs cél (a no-go
/// zónában).
double? performancePctOf(LabSample sample, Polar polar) {
  final target = _lookupTargetSpeed(
    polar: polar,
    twaDegrees: sample.absTwaDeg,
    twsKnots: sample.twsKnots,
  );
  if (target == null || target <= 0) return null;
  return 100 * sample.stwKnots / target;
}

/// Az időre súlyozott alsó kvantilis a `pct` szerint növekvő, nem üres
/// [sorted] listából: az első érték, amelynél a halmozott idő eléri a
/// teljes idő [fraction]-szorosát.
double weightedQuantile(List<WeightedPct> sorted, double fraction) {
  final total = sorted.fold(0, (sum, entry) => sum + entry.seconds);
  final threshold = fraction * total;
  var cumulative = 0;
  for (final entry in sorted) {
    cumulative += entry.seconds;
    if (cumulative >= threshold) return entry.pct;
  }
  return sorted.last.pct;
}

const _lookupTargetSpeed = LookupTargetSpeed();
