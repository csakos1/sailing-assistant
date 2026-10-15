import 'dart:math';

/// A látszólagos szélszög fokban (0–180) a valós szélből és a hajó
/// vízsebességéből (`docs/PLAN.md` P.3, diagnosztika).
///
/// A hajó a [stwKnots] sebességgel halad, a valós szél [twsKnots] erővel a
/// [absTwaDeg] szögből fúj; a látszólagos szél a kettő vektor-összege.
/// Sodródás, áramlás és a műszer saját hibája nélkül: arra jó, hogy a
/// fizikailag lehetetlen mintákat (a szél szinte szemből jön, mégis
/// haladunk) megtalálja, nem a műszer AWA-jának pótlására.
///
/// Pure függvény; véges, nem negatív bemenetre véges eredményt ad.
double apparentWindAngleDegrees({
  required double absTwaDeg,
  required double twsKnots,
  required double stwKnots,
}) {
  final twaRadians = absTwaDeg * pi / 180;
  final across = twsKnots * sin(twaRadians);
  final along = twsKnots * cos(twaRadians) + stwKnots;
  return (atan2(across, along) * 180 / pi).abs();
}
