import 'package:domain/src/value_objects/angle.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:meta/meta.dart';

/// A bóya felé szükséges kurzus-korrekció számítása az aktuális
/// effektív irányból.
///
/// Vékony wrapper a `Bearing - Bearing = Angle` operátorra (lásd
/// `bearing.dart`), amely signed shortest-path különbséget ad:
/// pozitív = jobbra (starboard) kell fordulni, negatív = balra (port),
/// az eredmény tartománya `[-180, +180)`. A use case maga nem számol —
/// a normalize-stratégia SSOT-ja az operátoron él, így ha az jövőben
/// változna, csak egy helyen módosul.
///
/// **Null-szemantika.** Ha az `effectiveDirection` null
/// (`BoatState.effectiveDirection` low-SOG drift vagy GPS / heading-
/// vesztés esetén ad null-t), a use case null-t ad vissza. Ez tudatos
/// választás az "Opció A" tervezésből: a 7.8 composite így nem
/// ternary-vel kezel, hanem közvetlenül a null-safe wrapper-t hívja, és
/// nem kell `!` force-unwrap. A `0°` érték szemantikailag "perfekt
/// kurzus" jelentésű, és nem keverhető a "nem tudjuk az irányt" esettel.
///
/// **Reference-konzisztencia.** A két [Bearing] paraméter azonos
/// [BearingReference]-szel kell rendelkezzen — a `Bearing - Bearing`
/// operátor assert-tel ellenőrzi dev mode-ban. A v1 hívási kontextusban
/// mindkettő [BearingReference.trueNorth]: `bearingToMark` a
/// `CalculateBearingToMark`-tól (mindig trueNorth), `effectiveDirection`
/// a `BoatState.effectiveDirection`-től (headingTrue vagy COG, mindkettő
/// trueNorth). A magnetic-magnetic pár is megengedett — a reference-
/// mismatch a hiba, nem a magnetic önmagában.
///
/// **Pure use case**: nincs állapot, idempotens.
@immutable
class CalculateCourseCorrection {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const CalculateCourseCorrection();

  /// A [bearingToMark] és az [effectiveDirection] közötti signed
  /// shortest-path különbség [Angle]-ként, vagy null ha
  /// [effectiveDirection] null. Részletek a class-doc-ban.
  Angle? call({
    required Bearing bearingToMark,
    required Bearing? effectiveDirection,
  }) {
    if (effectiveDirection == null) return null;
    return bearingToMark - effectiveDirection;
  }
}
