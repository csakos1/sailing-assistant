import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:shared/shared.dart';
import 'package:web_server/src/polar/polar_reference.dart';

// A polar-tesztek kozos mintai. Az egyszeru polar minden cellaja 5 kn,
// igy a % = 20 x STW (kn): 4 kn -> 80%, 5 kn -> 100%.

/// Az egyszeru polar `.pol` szovege.
const String flatPolarText =
    'twa/tws;4;8;12;16;20\n'
    '30;5;5;5;5;5\n'
    '60;5;5;5;5;5\n'
    '120;5;5;5;5;5\n';

/// Csomo -> m/s.
double mps(double knots) => knots * 1852 / 3600;

/// Az egyszeru polar.
Polar flatPolar() => switch (parseForetackPolar(flatPolarText)) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('hibas tesztpolar: $error'),
};

/// Referencia az egyszeru polarral.
PolarReference flatReference({
  String fingerprint = 'fp-1',
  List<StwCorrection> corrections = const [],
}) => PolarReference(
  polar: flatPolar(),
  corrections: corrections,
  fingerprint: fingerprint,
);

/// [count] egyenletes minta masodpercenkent a [start]-tol: TWA 60, TWS
/// 10 kn, STW [stwKnots].
List<PolarSample> steadySamples(
  DateTime start,
  int count, {
  double stwKnots = 4,
  int durationSeconds = 1,
}) => [
  for (var index = 0; index < count; index++)
    PolarSample(
      timestamp: start.add(Duration(seconds: index * durationSeconds)),
      twaDeg: 60,
      twsMps: mps(10),
      stwMps: mps(stwKnots),
      durationSeconds: durationSeconds,
    ),
];

/// Teljesitmeny egyetlen 5-os szelvodorrel es egyetlen hisztogram-ressel:
/// [seconds] masodperc [pct] %-on. A [pct] fel szazalekpontra kerek.
PolarPerformance uniformPerformance({
  required int seconds,
  required double pct,
  double? bestFivePct,
}) => PolarPerformance(
  measuredSeconds: seconds,
  pctSecondsSum: seconds * pct,
  twsMpsSecondsSum: seconds * 5.0,
  histogram: {(pct * 2).floor(): seconds},
  buckets: {5: PolarBucket(seconds: seconds, pctSecondsSum: seconds * pct)},
  bestFiveSecondsPct: bestFivePct,
);
