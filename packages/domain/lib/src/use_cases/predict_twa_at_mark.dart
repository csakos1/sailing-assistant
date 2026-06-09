import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:meta/meta.dart';

/// A következő bóya elérésekor várható True Wind Angle (TWA) becslése a
/// jelenlegi wind-shift trendből, konfidencia-kapuzott lineáris
/// extrapolációval (ADR 0021).
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
/// Ezért most maga a use case kapuz:
/// - [WindShiftConfidence.low] (r² ≤ 0.4) → nincs extrapoláció (slope = 0),
///   a predikció a jelenlegi TWD a köv. szárra vetítve;
/// - az extrapolációs időt a regressziós ablakra korlátozzuk
///   (`effectiveEta = min(timeToMark, trend.windowDuration)`);
/// - a teljes eltolást ±[_maxExtrapolationDeg] (alap 30°) közé vágjuk.
/// A `confidence` ettől függetlenül a `MarkPrediction.shiftConfidence`-en
/// is a UI rétegre jut a *megjelenítési* policyhoz (low → halvány jelzés).
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
  /// Const ctor — a use case stateless.
  const PredictTwaAtMark();

  /// Az extrapolált eltolás abszolút felső korlátja fokban (ADR 0021 D3).
  static const double _maxExtrapolationDeg = 30;

  /// A [nextLegBearing] és a [trend]-ből [timeToMark] időre kapuzottan
  /// extrapolált TWD közötti signed szög [Angle]-ként `[-180, +180)`,
  /// vagy `null` ha [trend] vagy [timeToMark] null. Részletek a
  /// class-doc-ban.
  Angle? call({
    required Bearing nextLegBearing,
    required WindShiftTrend? trend,
    required Duration? timeToMark,
  }) {
    if (trend == null || timeToMark == null) return null;

    // Low-konfidencián (r² ≤ 0.4) nem extrapolálunk: a slope megbízhatatlan.
    final shiftRate = trend.confidence == WindShiftConfidence.low
        ? 0.0
        : trend.shiftRateDegPerMinute;

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
    return predictedTwd - nextLegBearing;
  }
}
