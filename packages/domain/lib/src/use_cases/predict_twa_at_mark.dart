import 'package:domain/src/entities/twa_prediction.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/use_cases/estimate_prediction_confidence.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:meta/meta.dart';

/// A következő bóya elérésekor várható True Wind Angle (TWA) becslése a
/// jelenlegi wind-shift trendből, konfidencia-kapuzott lineáris
/// extrapolációval (ADR 0021), az érkezéskori előrejelzési hibasávval
/// (band) együtt (ADR 0023).
///
/// **Domain háttér.** A TWA a hajó kurzusa és a tényleges szélirány
/// (TWD) közötti signed szög (`[-180, +180)`, pozitív starboard,
/// negatív port). A predikció referenciája a **következő szár fix
/// iránya** (`nextLegBearing` = `bearing(aktív bója → következő bója)`),
/// NEM a pillanatnyi hajó→bója irány — így a predikció a fordulón nem
/// vált rossz halzára, és hosszú száron sem sodródik (ADR 0021 D1).
///
/// **Konfidencia-kapuzás a use case-ben (ADR 0021 D3).** A 0020/0021
/// előtt az extrapoláció a teljes-súlyú slope-ot alkalmazta r²-től
/// függetlenül, ami hosszú-ETA lábakon elszállt (2026-06-06 megfigyelés).
/// Ezért a use case kapuz:
/// - [WindShiftConfidence.low] (r² ≤ 0.4) → nincs extrapoláció (slope = 0),
///   a predikció a jelenlegi TWD a köv. szárra vetítve;
/// - az extrapolációs időt a regressziós ablakra korlátozzuk
///   (`effectiveEta = min(timeToMark, trend.windowDuration)`);
/// - a teljes eltolást ±[_maxExtrapolationDeg] (alap 30°) közé vágjuk.
///
/// **Előrejelzési hibasáv (ADR 0023).** A use case mostantól nem csak az
/// `Angle` TWA-t adja, hanem a [TwaPrediction]-be csomagolva a fokban
/// kifejezett band-et és a belőle bucketelt konfidenciát is — a 7.5b
/// `EstimatePredictionConfidence`-en át. A band horizontja a regresszió
/// idő-súlypontjától (`trend.meanSampleTime`) az érkezésig
/// (`now + effectiveEta`) tart. A **kapuzott (low r²) ágon a horizont 0**
/// (nem extrapolálunk), így a band = a reziduál-szórás. A `MarkPrediction.
/// shiftConfidence` így már NEM a `trend.confidence`-ből, hanem a band-ből
/// jön (a 7.8 composite-ban).
///
/// **Null-szemantika.** A use case `null`-t ad, ha `trend` vagy
/// `timeToMark` null. A köv. szár hiányát (utolsó láb) és a bója 50 m-es
/// freeze-körét a 7.8 `ComputeMarkPrediction` kezeli (ott lesz `null`),
/// nem itt.
///
/// **Reference-konzisztencia.** A `nextLegBearing` és a trend
/// `currentTwd` is [BearingReference.trueNorth]. A `nextLegBearing`-et a
/// 7.8 a `CalculateBearingToMark`-ból kapja (aktív→köv. bója), ami
/// trueNorth-ot ad; a reference-mismatch dev mode-ban `AssertionError`.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class PredictTwaAtMark {
  /// Const ctor — a band-becslő (7.5b) const-default dep, így a use case
  /// stateless marad, de a kapu + `effectiveEta` ismeretében itt komponál.
  const PredictTwaAtMark({
    EstimatePredictionConfidence confidence =
        const EstimatePredictionConfidence(),
  }) : _confidence = confidence;

  final EstimatePredictionConfidence _confidence;

  /// Az extrapolált eltolás abszolút felső korlátja fokban (ADR 0021 D3).
  static const double _maxExtrapolationDeg = 30;

  /// A [nextLegBearing]-hez mért, [timeToMark] időre kapuzottan
  /// extrapolált TWA + a hozzá tartozó band és konfidencia
  /// [TwaPrediction]-ként, vagy `null` ha [trend] vagy [timeToMark] null.
  /// A [now] az érkezés-horizont anchora (band-számítás). Részletek a
  /// class-doc-ban.
  TwaPrediction? call({
    required Bearing nextLegBearing,
    required WindShiftTrend? trend,
    required Duration? timeToMark,
    required DateTime now,
  }) {
    if (trend == null || timeToMark == null) return null;

    // Low-konfidencián (r² ≤ 0.4) nem extrapolálunk: a slope megbízhatatlan.
    final isGated = trend.confidence == WindShiftConfidence.low;
    final shiftRate = isGated ? 0.0 : trend.shiftRateDegPerMinute;

    // Az extrapolációt a regressziós ablakra korlátozzuk — ezen túl a
    // lineáris feltevés nem tartható (hosszú-ETA elszállás elleni védelem).
    final effectiveEta = timeToMark < trend.windowDuration
        ? timeToMark
        : trend.windowDuration;

    // fok/perc * mp / 60 = fok, ±30°-ra vágva.
    final shiftDeg = (shiftRate * effectiveEta.inSeconds / 60).clamp(
      -_maxExtrapolationDeg,
      _maxExtrapolationDeg,
    );

    // A `+` reference-t preserve-el és modulo 360-tal wrap-el; a `-`
    // signed shortest-path `[-180, +180)`-ot ad (SSOT a Bearing operátorokon).
    final predictedTwd = trend.currentTwd + Angle(degrees: shiftDeg);
    final twa = predictedTwd - nextLegBearing;

    // Band-horizont: a regresszió idő-súlypontjától az érkezésig. Kapuzott
    // ágon 0 (nem extrapolálunk), így a band = a reziduál-szórás.
    final horizon = isGated
        ? Duration.zero
        : now.add(effectiveEta).difference(trend.meanSampleTime);

    final estimate = _confidence(
      residualStdErrorDeg: trend.residualStdErrorDeg,
      slopeStdErrorDegPerMin: trend.slopeStdErrorDegPerMin,
      horizon: horizon,
    );

    return TwaPrediction(
      twa: twa,
      bandDegrees: estimate.bandDegrees,
      confidence: estimate.confidence,
    );
  }
}
