import 'package:domain/domain.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/target_speed.dart';
import 'package:shared/shared.dart';

/// A phone domain-állapotból összeállítja az órának küldendő [WatchPayload]-ot.
///
/// Pure függvény (Flutter nélkül tesztelhető): csak a megjelenítendő, már
/// kiszámolt értékeket emeli ki, mértékegység-konverzióval (SOG csomóban,
/// szögek előjeles fokban). A VMG előjeles, csomóban (4. szelet).
///
/// A critical figyelmeztetéseket a [localizeWarning] callbackkel lokalizálja
/// (ADR 0015 D4), így a builder l10n-agnosztikus marad: a provider a valódi
/// `warningMessage(...)`-et adja, a teszt egy fake-et.
WatchPayload buildWatchPayload({
  required BoatState boatState,
  required TrueTimeReading trueTime,
  required List<Warning> activeWarnings,
  required String Function(Warning warning) localizeWarning,
  required DateTime now,
  WindData? windData,
  MarkPrediction? prediction,
  TwdQuality twdQuality = TwdQuality.unavailable,
  double? targetSpeedKnots,
  double? vmgKnots,
}) {
  final criticalWarnings = <String>[
    for (final warning in activeWarnings)
      if (warning.severity == WarningSeverity.critical)
        localizeWarning(warning),
  ];

  final speed = boatState.speedOverGround;

  return WatchPayload(
    timestamp: now,
    gpsTimeUtc: trueTime.utc,
    isGpsTimeTrusted: _isTrusted(trueTime.source),
    sogKnots: speed == null ? null : speed.metersPerSecond * _knotsPerMps,
    vmgKnots: vmgKnots,
    currentTwa: windData?.trueAngleWater?.degrees,
    predictedTwaAtMark: prediction?.predictedTwaAtMark?.degrees,
    twdQuality: twdQuality.name,
    shiftConfidence: prediction?.shiftConfidence.name,
    forecastBandDegrees: prediction?.forecastBandDegrees,
    courseCorrection: prediction?.courseCorrection?.degrees,
    etaSeconds: prediction?.eta?.inSeconds,
    distanceMeters: prediction?.distanceToMark.meters,
    markName: prediction?.mark.name,
    targetSpeedPercent: targetSpeedPercent(
      liveSpeedMetersPerSecond:
          (boatState.speedThroughWater ?? boatState.speedOverGround)
              ?.metersPerSecond,
      targetSpeedKnots: targetSpeedKnots,
    ),
    criticalWarnings: criticalWarnings,
  );
}

// 1 m/s = 3600/1852 ≈ 1.943844 csomó. A Speed value object nem ad knots-gettert
// (csak metersPerSecond-öt), ezért a megjelenítési váltást itt végezzük.
const double _knotsPerMps = 1.943844;

// A polár-cél-sebesség százaléka: az élő sebesség (STW, SOG-fallback) osztva
// a cél-sebességgel, ×100. null, ha nincs cél, élő sebesség, vagy a cél nem
// pozitív (ADR 0028 Add. 3). STW-referenciájú polár, ezért STW az elsődleges.

// A GPS-idő akkor megbízható, ha valódi GNSS-fix vagy session-anchor a forrás
// (ADR 0012); a szinkronizálatlan fal-óra és a "nincs" nem (ADR 0015 D3).
bool _isTrusted(TrueTimeSource source) => switch (source) {
  TrueTimeSource.gnss || TrueTimeSource.sessionAnchor => true,
  TrueTimeSource.wallClockUnsynced || TrueTimeSource.none => false,
};
