import 'package:domain/src/value_objects/distance.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:meta/meta.dart';

/// A következő bóya elérésének becsült ideje (ETA): a hátralévő
/// `distance` és a jelenlegi SOG hányadosa.
///
/// **Domain háttér.** Az ETA azt becsli, mennyi idő múlva érjük el az
/// aktív bóyát a jelenlegi sebességgel. v1-ben **kizárólag SOG-alapú**:
/// a `distance` és a `speedOverGround` hányadosa. A polár-alapú ETA (a
/// hajó sebesség-polárjából, szélirány-függő optimummal) a v2 része,
/// amikor a polár-támogatás aktiválódik (manuális import + adatvezérelt
/// learning). A `MarkPrediction.etaSource` jelzi a UI-nak, hogy a
/// becslés `sog` (sikerült) vagy `unknown` (null) forrásból jött; az
/// `EtaSource.polar` az enumban már létezik, de v1-ben sosem áll elő.
///
/// **Null-szemantika.** `null`-t ad vissza, ha a `speedOverGround` null
/// (nincs SOG-jel), vagy ha a sebesség nem haladja meg a
/// drift-küszöböt. A null itt "nem tudjuk / nem értelmes", nem hiba.
/// Konzisztens a 7.3 `CalculateCourseCorrection` és a 7.5
/// `PredictTwaAtMark` null-safe-mintájával: a 7.8
/// `ComputeMarkPrediction` composite ezt a `Duration?`-t közvetlenül a
/// `PredictTwaAtMark.timeToMark`-jába csorgatja, force-unwrap nélkül.
///
/// **A drift-küszöb osztás-védő alja, NEM mozgás-küszöb.** A
/// [_minSpeedMetersPerSecond] (= 0.1 m/s, kb. 0.19 csomó) csak azt
/// zárja ki, hogy álló helyzetben (SOG → 0) a hányados végtelenhez
/// tartó, értelmetlen ETA-t adjon. Tudatosan **nem** azonos a
/// `BoatState.effectiveDirection` 1.5 csomós (kb. 0.7717 m/s)
/// küszöbével: az a COG-zaj problémát kezeli (kis sebességnél a GPS
/// COG zajos). Light-air driftnél (pl. 0.3 csomó) szándékosan adunk
/// ETA-t — Balatonon ilyenkor figyeli a skipper a legidegesebben —,
/// akkor is, ha az nagy szám.
///
/// **NaN-safety a feltétel szerkezetéből.** A guard pozitív feltétel
/// (`> _minSpeedMetersPerSecond`), nem negált. Ha a `speedOverGround`
/// valahogy NaN-t tárolna (a domain-be jutó adat elvileg validált, de
/// a default ctor nem ellenőriz), a `>` `false`-ot ad (NaN minden
/// összehasonlításra false), így null-t adunk — nem propagálunk NaN
/// ETA-t. NE írd át negált guard-clause-ra: az átengedné a NaN-t, és a
/// `NaN.round()` dobna.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes.
@immutable
class CalculateEtaToMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const CalculateEtaToMark();

  /// Drift-küszöb (m/s): ezen érték alatt (és pontosan ezen) a SOG-ot
  /// álló helyzetnek vesszük, és `null` ETA-t adunk. Osztás-védő alja,
  /// nem mozgás-küszöb — lásd a class-doc-ot.
  static const double _minSpeedMetersPerSecond = 0.1;

  /// A [distance] megtételéhez szükséges idő a [speedOverGround]
  /// sebességgel `Duration`-ként, vagy `null` ha [speedOverGround] null
  /// vagy nem haladja meg a drift-küszöböt. Részletek a class-doc-ban.
  Duration? call({
    required Distance distance,
    required Speed? speedOverGround,
  }) {
    if (speedOverGround != null &&
        speedOverGround.metersPerSecond > _minSpeedMetersPerSecond) {
      return Duration(
        seconds: (distance.meters / speedOverGround.metersPerSecond).round(),
      );
    }
    return null;
  }
}
