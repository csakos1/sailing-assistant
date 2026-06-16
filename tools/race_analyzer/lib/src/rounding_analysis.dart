import 'dart:math' as math;

import 'package:race_analyzer/src/snapshot_read_model.dart';

/// Az elemzes hangolhato parameterei (ADR 0025 D4, ADR 0026). Mindegyik
/// CLI-flag.
class AnalysisParams {
  /// Alapertelmezett hangolas.
  const AnalysisParams({
    this.settleSkip = const Duration(seconds: 10),
    this.settleWindow = const Duration(seconds: 20),
    this.cogToleranceDeg = 20,
    this.settleConfirm = const Duration(seconds: 3),
    this.leadTrustLevels = const {'high'},
  });

  /// A korozes utan ennyit MINDENKEPP kihagyunk, mire a COG-kapu nyilhat
  /// (floor; ADR 0026 D5).
  final Duration settleSkip;

  /// A kapu nyitasatol ezen az ablakon atlagoljuk a tenyleges TWA-t.
  final Duration settleWindow;

  /// A COG es a leg-irany megengedett elterese fokban; ezen belul a hajo
  /// "rajta van az uj legen" (ADR 0026 D3). 360 = a regi fix-ido mod (D6).
  final double cogToleranceDeg;

  /// A kapu ennyi ideig tarto folyamatos in-tolerance allapotra var a
  /// nyitashoz (debounce; ADR 0026 D4).
  final Duration settleConfirm;

  /// Mely `shiftConfidence`-szintek szamitanak "megbizhatonak" a lead-time-hoz.
  final Set<String> leadTrustLevels;
}

/// Egy boja-korozes predikalt-vs-tenyleges eredmenye (ADR 0025 D1). Az adott
/// leg-re (a korozott bojatol a kovetkezoig) szol, amire a predikcio
/// vonatkozott.
class RoundingResult {
  /// Egy korozes eredmenye.
  const RoundingResult({
    required this.fromMark,
    required this.toMark,
    required this.roundedAt,
    this.predictedTwaDeg,
    this.actualTwaDeg,
    this.forecastBandDeg,
    this.predictedConfidence,
    this.leadTime,
    this.actualSampleCount = 0,
  });

  /// A korozott boja (a leg INNEN indul).
  final String fromMark;

  /// A kovetkezo boja (a leg IDE tart) — erre szolt a predikcio.
  final String toMark;

  /// A korozes ideje (a markName-valtas elso tickje).
  final DateTime roundedAt;

  /// A leg-re josolt TWA fokban (a korozes elotti nem-null), vagy `null`.
  final double? predictedTwaDeg;

  /// A ténylegesen befutott TWA fokban (a beallasi ablak korkozepe),
  /// vagy `null`.
  final double? actualTwaDeg;

  /// A predikciot ado snapshot hibasavja fokban, vagy `null`.
  final double? forecastBandDeg;

  /// A predikciot ado snapshot konfidencia-szintje, vagy `null`.
  final String? predictedConfidence;

  /// Mennyivel a korozes elott lett es maradt megbizhato a joslat, vagy `null`,
  /// ha a korozeskor mar nem volt megbizhato.
  final Duration? leadTime;

  /// Hany snapshotbol atlagoltuk a tenyleges TWA-t (0 = nem volt eleg adat).
  final int actualSampleCount;

  /// A delta: tenyleges − predikalt, [-180, 180)-ra normalizalva; `null`, ha
  /// barmelyik oldal hianyzik.
  double? get deltaDeg {
    final predicted = predictedTwaDeg;
    final actual = actualTwaDeg;
    if (predicted == null || actual == null) return null;
    return wrapTo180(actual - predicted);
  }

  /// A tenyleges a sávon belul van-e (`|delta| <= band`); `null`, ha valami
  /// hianyzik.
  bool? get isWithinBand {
    final delta = deltaDeg;
    final band = forecastBandDeg;
    if (delta == null || band == null) return null;
    return delta.abs() <= band;
  }
}

/// A snapshot-folyambol kiszamolja a boja-korozesek predikalt-vs-tenyleges
/// eredmenyeit (ADR 0025). Tiszta fuggveny: a [snapshots] idorendben, a
/// [params] a hangolas. A korozeseket a `markName` valtasai jelzik (D4).
List<RoundingResult> analyzeRoundings(
  List<AnalyzerSnapshot> snapshots, {
  AnalysisParams params = const AnalysisParams(),
}) {
  return [
    for (final transition in _detectTransitions(snapshots))
      _analyzeTransition(snapshots, transition, params),
  ];
}

/// Egy szoget [-180, 180)-ra normalizal. Publikus, hogy a teszt kozvetlenul
/// is ellenorizhesse a wrap-szemantikat.
double wrapTo180(double degrees) {
  final wrapped = degrees % 360;
  return wrapped >= 180 ? wrapped - 360 : wrapped;
}

class _Transition {
  _Transition({
    required this.index,
    required this.fromMark,
    required this.toMark,
    required this.at,
  });

  /// A `snapshots`-beli index, ahol a `toMark` eloszor megjelenik (= korozes).
  final int index;
  final String fromMark;
  final String toMark;
  final DateTime at;
}

List<_Transition> _detectTransitions(List<AnalyzerSnapshot> snaps) {
  final out = <_Transition>[];
  String? previous;
  for (var i = 0; i < snaps.length; i++) {
    final name = snaps[i].markName;
    if (name != null && previous != null && name != previous) {
      out.add(
        _Transition(
          index: i,
          fromMark: previous,
          toMark: name,
          at: snaps[i].tickTime,
        ),
      );
    }
    if (name != null) previous = name;
  }
  return out;
}

RoundingResult _analyzeTransition(
  List<AnalyzerSnapshot> snaps,
  _Transition transition,
  AnalysisParams params,
) {
  final predicted = _lastPredictionBefore(snaps, transition.index);
  final samples = _settledActualTwa(snaps, transition, params);

  return RoundingResult(
    fromMark: transition.fromMark,
    toMark: transition.toMark,
    roundedAt: transition.at,
    predictedTwaDeg: predicted?.predictedTwaAtMarkDeg,
    forecastBandDeg: predicted?.forecastBandDeg,
    predictedConfidence: predicted?.shiftConfidence,
    actualTwaDeg: samples.isEmpty ? null : _circularMeanDeg(samples),
    actualSampleCount: samples.length,
    leadTime: _trustLeadTime(snaps, transition.index, params),
  );
}

// A korozes elotti utolso snapshot, ahol a predikcio nem null.
AnalyzerSnapshot? _lastPredictionBefore(
  List<AnalyzerSnapshot> snaps,
  int roundIndex,
) {
  for (var i = roundIndex - 1; i >= 0; i--) {
    if (snaps[i].predictedTwaAtMarkDeg != null) return snaps[i];
  }
  return null;
}

// A korozes utani COG-kapuzott beallasi ablakban mert TWA-mintak
// (ADR 0026). A leg-irany az elso nem-null bearingToMark a korozestol (a
// toMark messze -> boat->toMark ~ rhumb-line). A kapu az elso olyan,
// legalabb settleConfirm hosszu folyamatos in-tolerance COG-szakasz elejen
// nyilik, ami a settleSkip floor utan kezdodik; onnan settleWindow-nyit
// gyujtunk. Ha a kapu sosem nyilik -> ures (a leg nem merheto: pl.
// kereszt-leg, vagy a felvetel a beallas elott vegetert).
List<double> _settledActualTwa(
  List<AnalyzerSnapshot> snaps,
  _Transition transition,
  AnalysisParams params,
) {
  final legBearingDeg = _legBearingDeg(snaps, transition.index);
  if (legBearingDeg == null) return const [];

  final floor = transition.at.add(params.settleSkip);
  final windowStart = _gateOpenTick(
    snaps,
    transition.index,
    floor,
    legBearingDeg,
    params,
  );
  if (windowStart == null) return const [];

  final windowEnd = windowStart.add(params.settleWindow);
  final samples = <double>[];
  for (var i = transition.index; i < snaps.length; i++) {
    final tick = snaps[i].tickTime;
    if (tick.isBefore(windowStart)) continue;
    if (!tick.isBefore(windowEnd)) break; // idorend -> nincs feljebb
    final twa = snaps[i].currentTwaDeg;
    if (twa != null) samples.add(twa); // a null-check utan promotalt
  }
  return samples;
}

// A leg-irany: az elso nem-null bearingToMark a korozestol (ADR 0026 D2).
// A toMark a korozeskor meg messze van, igy a boat->toMark bearing a leg
// rhumb-line iranya; egyszer rogzitjuk (nem a pillanatnyi zaj).
double? _legBearingDeg(List<AnalyzerSnapshot> snaps, int roundIndex) {
  for (var i = roundIndex; i < snaps.length; i++) {
    final bearing = snaps[i].bearingToMarkDeg;
    if (bearing != null) return bearing;
  }
  return null;
}

// A COG-kapu nyitasanak tickje (ADR 0026 D3/D4): az elso, legalabb
// settleConfirm hosszu folyamatos in-tolerance szakasz eleje a floor utan;
// egy zajos COG-tick a futamot nullazza (debounce). null, ha nincs ilyen.
DateTime? _gateOpenTick(
  List<AnalyzerSnapshot> snaps,
  int roundIndex,
  DateTime floor,
  double legBearingDeg,
  AnalysisParams params,
) {
  DateTime? runStart;
  for (var i = roundIndex; i < snaps.length; i++) {
    final tick = snaps[i].tickTime;
    if (tick.isBefore(floor)) continue;
    final cog = snaps[i].cogDeg;
    final isInTolerance =
        cog != null &&
        wrapTo180(cog - legBearingDeg).abs() <= params.cogToleranceDeg;
    if (!isInTolerance) {
      runStart = null;
      continue;
    }
    runStart ??= tick;
    if (tick.difference(runStart) >= params.settleConfirm) return runStart;
  }
  return null;
}

// A korozesnel vegzodo megbizhato predikcio-futam hossza a korozesig
// (ADR 0027). A trailing freeze-tickeket (null predikcio, ADR 0021 50 m
// freeze) atlepjuk; a horgony az utolso VALODI (nem-null) predikcio. Ha az
// nem megbizhato -> null (a joslat nem maradt megbizhato a rakozelitesig,
// D2). A futam visszafele addig tart, amig folyamatosan valodi+megbizhato
// (null vagy untrusted tick megszakitja); lead-time = roundedAt - runStart,
// a freeze-t athidalva (D4).
Duration? _trustLeadTime(
  List<AnalyzerSnapshot> snaps,
  int roundIndex,
  AnalysisParams params,
) {
  // A trailing freeze (null predikcio) atlepese a korozes elott (D1).
  var i = roundIndex - 1;
  while (i >= 0 && snaps[i].predictedTwaAtMarkDeg == null) {
    i--;
  }
  // A horgony az utolso valodi predikcio; megbizhatonak kell lennie (D2).
  if (i < 0 || !_isTrustedPrediction(snaps[i], params)) return null;
  // A megbizhato futam vissza: null vagy untrusted tick megszakitja (D3).
  var startTick = snaps[i].tickTime;
  while (i - 1 >= 0 && _isTrustedPrediction(snaps[i - 1], params)) {
    i--;
    startTick = snaps[i].tickTime;
  }
  return snaps[roundIndex].tickTime.difference(startTick);
}

// Valodi ES megbizhato predikcio: nem-null predikcio + a shiftConfidence a
// megbizhato szintek kozt. A nem-null feltetel miatt a freeze-tickek a
// --lead-threshold low eseten sem szamitanak a futamba (ADR 0027 D5).
bool _isTrustedPrediction(AnalyzerSnapshot snap, AnalysisParams params) {
  return snap.predictedTwaAtMarkDeg != null && _isTrusted(snap, params);
}

bool _isTrusted(AnalyzerSnapshot snap, AnalysisParams params) {
  final confidence = snap.shiftConfidence;
  return confidence != null && params.leadTrustLevels.contains(confidence);
}

// Szogek korkozepe (egysegvektor-atlag), [-180, 180]. A naiv szamtani atlag a
// ±180 koruli wrap miatt hibazna.
double _circularMeanDeg(List<double> degrees) {
  var sumX = 0.0;
  var sumY = 0.0;
  for (final deg in degrees) {
    final rad = deg * math.pi / 180;
    sumX += math.cos(rad);
    sumY += math.sin(rad);
  }
  return math.atan2(sumY, sumX) * 180 / math.pi;
}
