import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:meta/meta.dart';

/// A következő bóya elérésekor várható True Wind Angle (TWA)
/// becslése a jelenlegi wind-shift trend-ből lineáris extrapolációval.
///
/// **Domain háttér.** A TWA a hajó kurzusa és a tényleges szélirány
/// (TWD) közötti signed szög (`[-180, +180)`, pozitív starboard,
/// negatív port). Tour-race kontextusban a TWA várható alakulása
/// határozza meg, hogy a következő szárra mire kell készülni (lift
/// vagy header, halzazás-igény, vitorla-trim). A 7.4
/// `CalculateWindShiftTrend` szolgáltatja az aktuális TWD-t és a
/// fok/perc shift-rátát; ez a use case ezt vetíti előre a
/// `timeToMark` időre, és a `courseToMark`-hoz mért signed szögként
/// adja vissza.
///
/// **Vékony wrapper a [Bearing] operátorokra.** A use case maga nem
/// normalize-zál: a `Bearing + Angle = Bearing` modulo-360 wrap-pel
/// és a `Bearing - Bearing = Angle` signed shortest-path
/// `[-180, +180)`-tal adják a teljes számítást (lásd `bearing.dart`).
/// SSOT a normalize-stratégián: ha az operátor megváltozik, csak ott
/// módosul.
///
/// **Null-szemantika.** A use case `null`-t ad vissza, ha `trend`
/// vagy `timeToMark` null. Mindkettő tudatos null-safe-pattern: a 7.4
/// `CalculateWindShiftTrend` `WindShiftTrend?`-t ad insufficient /
/// degenerate signal esetén, a 7.6 `CalculateEtaToMark` `Duration?`-t
/// SOG-vesztés esetén. A 7.8 `ComputeMarkPrediction` composite így
/// nem ternary-vel kezel a hívás helyén, hanem közvetlenül ezt a
/// null-safe wrapper-t hívja, és nem kell `!` force-unwrap downstream.
/// Analóg a 7.3 `CalculateCourseCorrection` mintával.
///
/// **Low-confidence nem itt szűrünk.** A trend `confidence` érték a
/// `MarkPrediction.shiftConfidence`-en jut a UI rétegre, ami eldönti,
/// hogyan jeleníti meg (low esetén jelzés-szinten, medium/high-tól
/// teljes értékű). Ez a use case csak számol; a megjelenítési policy
/// nem itt dől el.
///
/// **Reference-konzisztencia.** A `courseToMark` és a trend-en
/// keresztül érkező `currentTwd` is [BearingReference.trueNorth]-
/// referenciájú kell legyen. A `WindShiftTrend.currentTwd` invariáns
/// szerint mindig trueNorth, a `courseToMark`-ot a 7.8 a
/// `CalculateBearingToMark`-ból kapja, ami szintén trueNorth-ot ad.
/// A reference-mismatch dev mode-ban `AssertionError`-t ad a
/// `Bearing - Bearing` operátorban.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class PredictTwaAtMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const PredictTwaAtMark();

  /// A [courseToMark] és a [trend]-ből [timeToMark] időre extrapolált
  /// TWD közötti signed szög [Angle]-ként `[-180, +180)`-ban, vagy
  /// `null` ha [trend] vagy [timeToMark] null. Részletek a
  /// class-doc-ban.
  Angle? call({
    required Bearing courseToMark,
    required WindShiftTrend? trend,
    required Duration? timeToMark,
  }) {
    if (trend == null || timeToMark == null) return null;

    // Lineáris extrapoláció: fok/perc * másodperc / 60 = fok.
    final shiftDeg = trend.shiftRateDegPerMinute * timeToMark.inSeconds / 60;

    // A `+` reference-t preserve-el és modulo 360-tal wrap-el; a `-`
    // signed shortest-path `[-180, +180)`-ot ad. SSOT a Bearing
    // operátorokon, lásd class-doc.
    final predictedTwd = trend.currentTwd + Angle(degrees: shiftDeg);
    return predictedTwd - courseToMark;
  }
}
