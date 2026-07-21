import 'package:domain/src/value_objects/depth.dart';
import 'package:domain/src/value_objects/depth_alert_state.dart';
import 'package:meta/meta.dart';

/// Pure use case: a sekélyvíz-riasztás ratchet-állapotgépe (ADR 0031
/// D3/D4).
///
/// **Pure.** Nincs állapota, nincs mellékhatása: a korábbi állapotot
/// paraméterként kapja és újat ad vissza, ezért mockolás nélkül,
/// exhaustive-an tesztelhető. Az állapot tárolása a `RaceEngine`
/// reducer dolga.
///
/// Az állapotgép a `previous` állapotból és az aktuális mélységből:
///
/// - **szétkapcsolás** → reset (`isActive = false`, horgony törölve),
///   mert stale adaton nem riasztunk (ADR 0014 D5 összhang). A
///   `buzzCounter` ilyenkor sem csökken.
/// - **hiányzó mélység** → változatlan `previous`. Egy kieső mondat nem
///   zárhat le futó epizódot; a `BoatState` amúgy is carry-forwardol.
/// - **`meters >= clearDepthMeters`** → az epizód lezárul, reset. Nincs
///   új rezgés, a számláló nem nő.
/// - **belépés** (`!isActive && meters <= triggerDepthMeters`) → aktív,
///   a horgony a jelen vödör, **rezgés**.
/// - **új mélypont** (aktív epizód, a jelen vödör kisebb az eddigi
///   legkisebbnél) → horgony-frissítés, **rezgés**.
/// - egyébként (hiszterézis-sáv vagy már látott szint) → aktív marad,
///   nincs új rezgés.
///
/// A trigger és a clear közti rés a hiszterézis: a küszöb körül
/// ingadozó mélység nem pattogtatja az epizódot.
@immutable
class EvaluateDepthAlert {
  /// Állapotmentes use case; a default ctor const.
  const EvaluateDepthAlert();

  /// A riasztás küszöbe méterben: ezt ELÉRVE (`<=`) indul az epizód.
  /// Fix v1 konstans (ADR 0031 D3), a jeladó-alatti nyers mélységre.
  static const double triggerDepthMeters = 2.5;

  /// A feloldás küszöbe méterben: ezt ELÉRVE (`>=`) zárul az epizód.
  /// A triggernél magasabb — ez adja a hiszterézist (ADR 0031 D3).
  static const double clearDepthMeters = 3;

  // A ratchet lépcsőfoka reciprokként: 10 vödör méterenként = 0,1 m-es
  // lépcső (ADR 0031 D3). Tudatosan EGÉSZ osztó: a `meters / 0.1`
  // lebegőpontos alullövése (2.3 / 0.1 = 22.999...) egy teljes
  // lépcsővel lejjebb sorolna, a `* 10 ... / 10` viszont pontos.
  static const int _bucketsPerMeter = 10;

  /// A [previous] állapotból, a friss [depth]-ből és a kapcsolat
  /// állapotából ([isConnected]) számolt új epizód-állapot.
  DepthAlertState call({
    required DepthAlertState previous,
    required Depth? depth,
    required bool isConnected,
  }) {
    // A számlálót a resetek is átviszik: a monotonitás a felfutó-él
    // detektálás előfeltétele az órán.
    if (!isConnected) {
      return DepthAlertState(buzzCounter: previous.buzzCounter);
    }
    if (depth == null) {
      return previous;
    }

    final meters = depth.meters;
    if (meters >= clearDepthMeters) {
      return DepthAlertState(buzzCounter: previous.buzzCounter);
    }

    final bucket = _bucketOf(meters);
    final lowest = previous.lowestBuzzedBucket;

    if (!previous.isActive) {
      // A hiszterézis-sávban (trigger < meters < clear) INAKTÍVBÓL nem
      // indul epizód — belépni csak a triggert elérve lehet.
      if (meters > triggerDepthMeters) {
        return previous;
      }
      return DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: bucket,
        buzzCounter: previous.buzzCounter + 1,
      );
    }

    // Aktív epizód: csak ÚJ mélypont rezeg. A visszanövés utáni ismételt
    // csökkenés egy már látott szintre szándékosan néma.
    if (lowest == null || bucket < lowest) {
      return DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: bucket,
        buzzCounter: previous.buzzCounter + 1,
      );
    }

    return previous;
  }

  // A mélység lefelé kerekítve a 0,1 m-es vödrére. Az epszilon a
  // szorzás alullövését javítja (2.3 * 10 = 22.999...), ami enélkül a
  // szomszédos, alacsonyabb vödörbe sorolna.
  double _bucketOf(double meters) =>
      (meters * _bucketsPerMeter + 1e-9).floorToDouble() / _bucketsPerMeter;
}
