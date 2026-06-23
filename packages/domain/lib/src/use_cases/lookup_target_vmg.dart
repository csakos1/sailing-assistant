import 'dart:math';

import 'package:domain/src/entities/polar.dart';
import 'package:domain/src/use_cases/lookup_target_speed.dart';

/// A pillanatnyi szélsebesség (TWS) mellett elérhető legjobb VMG-t
/// (target-VMG, csomóban, előjeles) adja vissza a [Polar] rácsból: a hajó
/// pillanatnyi TWA-ja dönti el a halz-irányt (fel- vagy lemenő), és a
/// használt sávban a target-vízsebesség × cos(TWA) szélsőértékét keressük.
///
/// **Pure use case.** Nincs állapota, nincs mellékhatása; a `call`
/// kizárólag a bemenetekből számol. Const-konstruálható, így a háttér-
/// engine és a tesztek olcsón példányosítják. A target-vízsebességet a
/// kompozícióban használt `LookupTargetSpeed` adja (DRY: a no-go-kapu és a
/// bilineáris interpoláció ott már validált); itt csak a sávot pásztázzuk
/// és a VMG-szélsőértéket választjuk ki.
///
/// **Előjel.** A visszaadott VMG előjeles, megegyezően a `ComputeVmg` élő
/// VMG-jével: pozitív = szél felé (felmenő, `|TWA| < 90`), negatív =
/// széltől el (lemenő, `|TWA| >= 90`). Így az élő és a target-VMG
/// közvetlenül összevethető (élő 4.5 vs. cél 6.1; lemenőn -3.8 vs. -4.6).
///
/// **Sáv.** Felmenőn a no-go küszöb ([Polar.noGoThresholdDegrees]) és 90°
/// között, lemenőn 90° fölött 180°-ig pásztázunk, 1°-os lépéssel: a polár
/// bilineáris lookupja sima, így a durva 5°-os rács helyett a finom
/// mintavétel jitter-mentes optimumot ad (1 Hz-en triviális). A 90°-os
/// beam-szöget kihagyjuk (ott a VMG kb. 0, sosem optimum).
///
/// `null` jön vissza, ha nincs értelmes target: nem-véges bemenetre, vagy
/// ha a sávban sehol nincs polár-adat (üres rács-környezet).
final class LookupTargetVmg {
  /// Const konstruktor — a use case stateless és pure.
  const LookupTargetVmg();

  /// A kompozícióban használt cél-sebesség lookup (no-go-kapu + bilineáris
  /// interpoláció). Pure és const, ezért static const mező.
  static const _lookupTargetSpeed = LookupTargetSpeed();

  /// A [polar] rácsból a [twsKnots] melletti elérhető legjobb (előjeles)
  /// VMG, a [twaDegrees] által meghatározott halz-irányban, vagy `null`,
  /// ha nincs target.
  double? call({
    required Polar polar,
    required double twaDegrees,
    required double twsKnots,
  }) {
    // Védőháló: nem-véges bemenetre (NaN/±végtelen) nincs értelmes lookup.
    if (!twaDegrees.isFinite || !twsKnots.isFinite) return null;

    // A halz-irányt a pillanatnyi |TWA| dönti el; a no-go (<25°) is
    // felmenő, mert ott is a felmenő cél a viszonyítás.
    final isUpwind = twaDegrees.abs() < 90;

    // A pásztázott sáv: felmenőn [no-go, 90), lemenőn (90, 180]. A 90°-os
    // beam-szöget egyik sem tartalmazza (VMG kb. 0).
    final startAngle = isUpwind ? Polar.noGoThresholdDegrees.ceil() : 91;
    final endAngle = isUpwind ? 89 : 180;

    double? bestVmg;
    for (var angle = startAngle; angle <= endAngle; angle++) {
      final targetSpeed = _lookupTargetSpeed(
        polar: polar,
        twaDegrees: angle.toDouble(),
        twsKnots: twsKnots,
      );
      // Üres vödör-környezet ezen a szögön — kihagyjuk.
      if (targetSpeed == null) continue;

      final vmg = targetSpeed * cos(angle * pi / 180);
      // Felmenőn a legnagyobb (legpozitívabb), lemenőn a legkisebb
      // (legnegatívabb) VMG a cél — mindkettő a 0-tól legtávolabbi.
      if (bestVmg == null || (isUpwind ? vmg > bestVmg : vmg < bestVmg)) {
        bestVmg = vmg;
      }
    }
    return bestVmg;
  }
}
