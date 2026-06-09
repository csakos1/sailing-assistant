import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/entities/twd_estimate.dart';
import 'package:domain/src/entities/twd_quality.dart';
import 'package:domain/src/entities/wind_data.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:meta/meta.dart';

/// A True Wind Direction (TWD) derivációja a ground-track és a
/// csúcs-relatív szélszögből (ADR 0020).
///
/// **Miért nem a `MWD`.** A `WindData.trueDirectionGround` (`MWD`) a
/// Vulcanban a mágneses heading-ből számolódik, a ZG100 iránytű viszont
/// heading-függő kalibrációs hibát hordoz; így a `MWD` a hajó irányával
/// vándorol, és a wind-shift regresszió minden fordulónál hamis ~100°-os
/// elfordulást lát. A `WindData.trueAngleWater` (`MWV` true, boat-frame)
/// és a `BoatState.courseOverGround` (ground-track) ezzel szemben épek.
///
/// **A deriváció.** `TWD = COG_true + twaBow`, ahol a `Bearing + Angle`
/// operátor a trueNorth referenciát megtartja és modulo 360-nal wrap-el.
/// A `+` mod-360 jellege miatt a [WindData.trueAngleWater] sign-konvenciója
/// (signed `[-180,180)` vagy `0..360`) **nem számít** — az eredmény
/// azonos. A COG nem ugrik a fordulón (folytonos ground-track), a leeway
/// pedig ~5–10° abszolút eltolás, ami a trendet — a predikció bemenetét —
/// nem érinti.
///
/// **SOG-kapu + hold-last-good (ADR 0020 D2).** Alacsony sebességnél a
/// GPS-noise dominálja a COG-t, ezért a deriváció feltétele
/// `SOG > [_cogValidMinSpeed]` (alap 1.5 csomó). A küszöb fölött, ismert
/// COG és bow-TWA mellett `live` becslés; egyébként a `lastGoodTwd`-t
/// tartjuk (`held`), vagy ha az sincs, `unavailable`. A minőséget a
/// `TwdEstimate.quality` hordozza, és onnan a `WindObservation.twdQuality`.
///
/// **Pure use case**: nincs állapot, idempotens, side effect mentes. Az
/// "utolsó jó TWD" görgetése (a `lastGoodTwd` forrása) az application
/// rétegé — a domain stateless marad.
@immutable
class DeriveTrueWindDirection {
  /// Const ctor — a use case stateless.
  const DeriveTrueWindDirection();

  /// Az érdemi mozgás SOG-küszöbe; ez alatt a COG GPS-noise-os, ezért
  /// nem deriválunk. 1.5 csomó ≈ 0.7717 m/s (lásd `BoatState`).
  static const _cogValidMinSpeed = Speed(metersPerSecond: 0.7717);

  /// A [boatState] (COG, SOG) és a [wind] (bow-TWA) alapján derivált TWD,
  /// SOG-kapuval és hold-last-good-dal. A [lastGoodTwd] az előző `live`
  /// becslés (a held-ághoz). Részletek a class-doc-ban.
  TwdEstimate call({
    required BoatState boatState,
    required WindData wind,
    Bearing? lastGoodTwd,
  }) {
    // Lokális promóció a force-unwrap helyett (field nem promótálható).
    final cog = boatState.courseOverGround;
    final sog = boatState.speedOverGround;
    final twaBow = wind.trueAngleWater;

    final isMoving =
        sog != null && sog.metersPerSecond > _cogValidMinSpeed.metersPerSecond;

    if (cog != null && twaBow != null && isMoving) {
      // Bearing + Angle → trueNorth, modulo 360 (sign-agnosztikus).
      return TwdEstimate(twd: cog + twaBow, quality: TwdQuality.live);
    }

    // Hold-last-good: nincs élő deriváció → utolsó jó érték, vagy nincs.
    return lastGoodTwd == null
        ? const TwdEstimate.unavailable()
        : TwdEstimate(twd: lastGoodTwd, quality: TwdQuality.held);
  }
}
