import 'package:domain/src/entities/polar.dart';
import 'package:domain/src/value_objects/angle.dart';

/// A VMG-optimum szögre vezető steer-korrekciót adja: hány fokot kell
/// élesedni vagy leesni, hogy a pillanatnyi TWA a polár VMG-optimum
/// szögére álljon. Az eredmény előjeles [Angle], a kurzus-korrekcióval
/// AZONOS konvencióban: pozitív = jobbra (starboard), negatív = balra
/// (port). A megjelenítés a fordulás irányába mutató nyíl + |korrekció|.
///
/// **Bója-független.** A szélhez vetített VMG-optimumra korrigál (a polár
/// és a TWS függvénye), nem a bója felé — az felmenőn mohó/félrevezető
/// lenne. A "rá tudok-e menni a bójára" külön kérdés, azt a bearing +
/// `CalculateCourseCorrection` adja.
///
/// **Csak a szöget zárja be.** A target VMG-szám eléréséhez a polár-
/// sebesség is kell; azt a meglévő target-% méri. Ha a korrekció ~0°, de
/// még a target alatt vagyunk, az trim-/sebesség-probléma, nem szög.
///
/// **Előjelezés.** Az `optimumTwaMagnitude` pozitív magnitúdó; az előjelét
/// a `currentTwa` halza adja (port → negatív optimum), majd a korrekció =
/// `currentTwa - optimumSigned` (előjeles `Angle - Angle`). A nyíl így a
/// tényleges fordulás-irányba mutat, és tackeléskor a halz előjel-váltása
/// magától átfordítja.
///
/// **Pure use case.** Nincs állapota, nincs mellékhatása; const-
/// konstruálható. `null`-t ad vissza, ha:
/// - a bemenet nem-véges (NaN/±végtelen), vagy
/// - no-go/vasban vagyunk (`|currentTwa| < `[Polar.noGoThresholdDegrees]),
///   mert ott a halz kétértelmű, nincs eldönthető optimum-oldal.
///
/// A szél-/TWS-/polár-hiány és a gyenge `twdQuality` szerinti elnyomás a
/// hívó (engine-helper) felelőssége: oda nem jut el a hívás, ha nincs
/// optimum vagy gyenge a minőség.
final class ComputeVmgSteerCorrection {
  /// Const konstruktor — a use case stateless és pure.
  const ComputeVmgSteerCorrection();

  /// A [currentTwa] (előjeles) és a polár VMG-optimum szöge közötti
  /// steer-korrekció, vagy `null` nem-véges bemenetre / no-go esetén. Az
  /// [optimumTwaMagnitude] a `LookupTargetVmg` ugyanazon pásztázásából
  /// jövő pozitív optimum-magnitúdó (fok).
  Angle? call({
    required Angle currentTwa,
    required double optimumTwaMagnitude,
  }) {
    // Védőháló: nem-véges bemenetre nincs értelmes korrekció.
    if (!currentTwa.degrees.isFinite || !optimumTwaMagnitude.isFinite) {
      return null;
    }
    // No-go/vasban a halz kétértelmű — nincs eldönthető optimum-oldal.
    if (currentTwa.degrees.abs() < Polar.noGoThresholdDegrees) {
      return null;
    }
    // Az optimum magnitúdóját a pillanatnyi TWA halzára előjelezzük:
    // starboard (poz. TWA) → poz., port (neg. TWA) → neg. optimum.
    final optimumSigned = optimumTwaMagnitude.abs() * currentTwa.degrees.sign;
    // Előjeles Angle - Angle: poz. = jobbra fordulás. A fordulás iránya a
    // halztól függ (felmenőn élesedés/leesés), a kijelzés ezt tükrözi.
    return currentTwa - Angle(degrees: optimumSigned);
  }
}
