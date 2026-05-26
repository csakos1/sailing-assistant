import 'package:domain/domain.dart';

/// Szél-állapot akkumulátor: a beérkező szél-mondatok mezőit gyűjti, és
/// minden frissítésnél friss [WindData] snapshotot ad — de csak akkor, ha
/// a látszó (apparent) szél már megérkezett (apparent-gate).
///
/// A `NmeaToDomainMapper` delegál ide, mező-szintű felülettel
/// ([applyApparent] / [applyTrueWater] / [applyTrueDirection]), hogy az
/// aggregátor csak domain value objectektől függjön, ne a parser
/// `DecodedSentence` családjától.
///
/// **Stateful.** A legfrissebb mezőket privát mutable mezőkben tartja; egy
/// frissítés a többi (stale) mezőt érintetlenül hagyja, és a következő
/// snapshot ezeket továbbviszi. Friss [WindData]-t építünk (nem
/// [WindData.copyWith]), mert a copyWith nem tud opcionális mezőt null-ra
/// állítani — az aggregátor viszont sosem nulláz vissza, csak felülír.
class WindAggregator {
  // A legfrissebb szél-mezők; az apparent pár hiánya a gate (amíg null,
  // nincs kiadható snapshot).
  Angle? _apparentAngle;
  Speed? _apparentSpeed;
  Angle? _trueAngleWater;
  Speed? _trueSpeedWater;
  Bearing? _trueDirectionGround;

  /// Frissíti a látszó (apparent) szél mezőit (AWA + AWS), és visszaadja a
  /// friss snapshotot a [now] időbélyeggel.
  ///
  /// A visszatérés non-null: az apparent ezzel a hívással garantáltan jelen
  /// van, így a gate teljesül.
  WindData applyApparent(Angle angle, Speed speed, DateTime now) {
    _apparentAngle = angle;
    _apparentSpeed = speed;
    // Az apparent most már be van állítva, így a snapshot sosem null.
    return _snapshot(now)!;
  }

  /// Frissíti a víz-referenciás valódi szél mezőit (TWA-water + TWS-water),
  /// és visszaadja a friss snapshotot a [now] időbélyeggel — vagy `null`,
  /// ha az apparent szél még nem érkezett meg (apparent-gate).
  WindData? applyTrueWater(Angle angle, Speed speed, DateTime now) {
    _trueAngleWater = angle;
    _trueSpeedWater = speed;
    return _snapshot(now);
  }

  /// Frissíti a ground-referenciás valódi szélirányt (TWD), és visszaadja a
  /// friss snapshotot a [now] időbélyeggel — vagy `null`, ha az apparent
  /// szél még nem érkezett meg (apparent-gate).
  WindData? applyTrueDirection(Bearing direction, DateTime now) {
    _trueDirectionGround = direction;
    return _snapshot(now);
  }

  // Friss snapshot a legfrissebb mezőkből, vagy null ha az apparent pár
  // (AWA + AWS) még hiányzik.
  WindData? _snapshot(DateTime now) {
    final apparentAngle = _apparentAngle;
    final apparentSpeed = _apparentSpeed;
    if (apparentAngle == null || apparentSpeed == null) {
      return null;
    }
    return WindData(
      apparentAngle: apparentAngle,
      apparentSpeed: apparentSpeed,
      trueAngleWater: _trueAngleWater,
      trueSpeedWater: _trueSpeedWater,
      trueDirectionGround: _trueDirectionGround,
      timestamp: now,
    );
  }
}
