import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/entities/eta_source.dart';
import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/entities/mark_prediction.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/use_cases/calculate_bearing_to_mark.dart';
import 'package:domain/src/use_cases/calculate_course_correction.dart';
import 'package:domain/src/use_cases/calculate_distance_to_mark.dart';
import 'package:domain/src/use_cases/calculate_eta_to_mark.dart';
import 'package:domain/src/use_cases/predict_twa_at_mark.dart';
import 'package:meta/meta.dart';

/// Composite use case: a Phase 1 számító use case-eket egyetlen
/// [MarkPrediction] snapshot-tá fűzi össze a UI számára
/// (ARCHITECTURE.md 7.8). A főképernyő és a watch 1 Hz-en hívja az
/// aktuális [BoatState], [Mark] és [WindShiftTrend] értékekkel.
///
/// **Pure use case.** Nincs állapota; a `now`-t injektáljuk a [call]-ba
/// (nem belső `DateTime.now()`), így a tick konzisztens időképpel
/// dolgozik, és fix időbélyeggel, mockolás nélkül tesztelhető.
///
/// **Const-default DI.** Mind az öt függő use case stateless, pure és
/// const-konstruálható, ezért const-default paraméterekként kapja őket
/// a ctor: default híváskor nincs bedrótozás (`const
/// ComputeMarkPrediction()`), teszthez viszont bármelyik dep
/// felülírható a named paraméterrel. A 7.7 `MarkRoundingDetector`
/// nem-injektált mintájával szemben itt megtartjuk ezt a seam-et (a
/// composite a v2 belépési pontja: `PolarRepository`, polár-aware ETA).
/// A ctor `const`, az osztály `@immutable`.
///
/// **Mark-rounding nincs benne** — az állapotos `MarkRoundingDetector`
/// (7.7) az application rétegben fut külön (8.4).
@immutable
class ComputeMarkPrediction {
  /// Létrehozás opcionális dep-override-okkal; default-ban mind const
  /// példány (lásd a class-doc const-default szakaszát).
  const ComputeMarkPrediction({
    CalculateBearingToMark bearing = const CalculateBearingToMark(),
    CalculateDistanceToMark distance = const CalculateDistanceToMark(),
    CalculateCourseCorrection correction = const CalculateCourseCorrection(),
    CalculateEtaToMark eta = const CalculateEtaToMark(),
    PredictTwaAtMark predict = const PredictTwaAtMark(),
  }) : _bearing = bearing,
       _distance = distance,
       _correction = correction,
       _eta = eta,
       _predict = predict;

  final CalculateBearingToMark _bearing;
  final CalculateDistanceToMark _distance;
  final CalculateCourseCorrection _correction;
  final CalculateEtaToMark _eta;
  final PredictTwaAtMark _predict;

  /// Egyetlen prediction-snapshot az [activeMark]-ra a [boatState] és a
  /// [trend] aktuális értékéből, [now] időbélyeggel.
  ///
  /// `null`-t ad, ha nincs aktív bója ([activeMark] == null) vagy nincs
  /// pozíció (`boatState.position` == null) — ekkor a bearing/distance
  /// sem értelmezhető. A [trend]-et kész állapotban kapja (a provider
  /// hívja a 7.4-et); a window-kezelés az application réteg dolga (SRP).
  ///
  /// A részeredmények null-szemantikája átöröklődik a [MarkPrediction]-
  /// be: nincs effektív irány → `courseCorrection` null; SOG drift alatt
  /// → `eta` null és `etaSource` `unknown`; nincs (elég jó) trend →
  /// `predictedTwaAtMark` null és `shiftConfidence` `low`.
  MarkPrediction? call({
    required Mark? activeMark,
    required BoatState boatState,
    required WindShiftTrend? trend,
    required DateTime now,
  }) {
    // Lokális promóció a `!` force-unwrap helyett: a field-et a
    // null-check nem promótálja, a lokális változót igen.
    final position = boatState.position;
    if (activeMark == null || position == null) {
      return null;
    }

    final bearing = _bearing(position, activeMark.position);
    final distance = _distance(position, activeMark.position);
    final correction = _correction(
      bearingToMark: bearing,
      effectiveDirection: boatState.effectiveDirection,
    );
    final eta = _eta(
      distance: distance,
      speedOverGround: boatState.speedOverGround,
    );
    final predictedTwa = _predict(
      courseToMark: bearing,
      trend: trend,
      timeToMark: eta,
    );

    return MarkPrediction(
      mark: activeMark,
      bearingToMark: bearing,
      courseCorrection: correction,
      distanceToMark: distance,
      eta: eta,
      etaSource: eta != null ? EtaSource.sog : EtaSource.unknown,
      predictedTwaAtMark: predictedTwa,
      shiftConfidence: trend?.confidence ?? WindShiftConfidence.low,
      calculatedAt: now,
    );
  }
}
