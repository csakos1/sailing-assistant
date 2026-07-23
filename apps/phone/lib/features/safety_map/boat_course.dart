import 'package:domain/domain.dart';

/// A sebesség-küszöb, ami alatt a COG-ból származó irány nem jelenik meg
/// az élő biztonsági térképen (ADR 0037 D12). Alap: 1 csomó.
///
/// **Külön nevesített konstans**, NEM a 2 csomós `headingCheckMinSpeed`
/// (ADR 0020 D5) újrahasználata: az a heading-ellenőrzést szolgálja, és
/// két független döntés egy konstanson keresztüli összekötése rejtett
/// csatolás lenne — a küszöb hangolása egyszer csak a másik viselkedést
/// is elmozdítaná.
///
/// A projektben nincs nevesített csomó-átváltás, ezért az érték m/s-ban
/// áll itt, a `BoatState` 1,5 csomós küszöbének mintájára (0.7717 m/s).
const Speed boatCourseMinSpeed = Speed(metersPerSecond: 0.5144);

/// A megjelenítéshez használható haladási irány (COG), vagy `null`.
///
/// Három feltételnek kell teljesülnie: van COG, van SOG, és a SOG eléri
/// a [boatCourseMinSpeed] küszöböt. Kis sebességnél a COG zaj — az
/// irányvektor ezt a képernyő széléig felnagyítaná, a hajó-szimbólum
/// pedig egy fagyott irányba mutatna, ugyanolyan magabiztosan, mint
/// élesben. „A hiányzó vonal őszinte, a remegő hazudik" (D12).
///
/// **A `BoatState.effectiveDirection` itt NEM használható.** Az a küszöb
/// alatt a `headingTrue`-ra esik vissza, tehát épp arra a ZG100-heading-re,
/// amitől a D11 elhatárolódik — és épp abban a sebesség-tartományban,
/// ahol a hiba a legnagyobb.
Bearing? usableCourseOverGround(BoatState boat) {
  final course = boat.courseOverGround;
  final speed = boat.speedOverGround;
  if (course == null || speed == null) return null;
  if (speed.metersPerSecond < boatCourseMinSpeed.metersPerSecond) {
    return null;
  }
  return course;
}
