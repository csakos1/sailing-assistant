/// A sekély-víz riasztás két pure döntése (ADR 0031 D4): mikor rezegjen az
/// óra, és mikor látszódjon az overlay.
///
/// A `confidence_haptic_edge.dart` mintáját követi: a `RaceShell`-ből
/// kiemelt, widget-mentes predikátumok, önállóan tesztelhetők.
library;

/// A `depthBuzzCounter` **változó** élének detektora.
///
/// Igaz, ha van aktív riasztás ([currentDepthMeters] nem null) ÉS a
/// számláló értéke más, mint az előző payloadban volt.
///
/// Szándékosan `!=` és nem `>`. A számláló a telefon engine-jében
/// in-memory monoton, de az engine újraindulása visszaejti nullára — egy
/// `>` összehasonlítás ilyenkor csendben elnyelné a következő riasztást.
/// Zátonyveszélynél a téves rezgés olcsóbb hiba, mint az elmaradt.
///
/// A [currentDepthMeters]-gate azt zárja ki, hogy a puszta számláló-esés
/// (engine-újraindulás aktív epizód nélkül) rezgést váltson ki.
bool isRisingDepthBuzz({
  required int previousCounter,
  required int currentCounter,
  required double? currentDepthMeters,
}) => currentDepthMeters != null && currentCounter != previousCounter;

/// Látszódjon-e a teljes-képernyős sekély-víz overlay.
///
/// Igaz, ha van aktív riasztás ([depthAlertMeters] nem null), és a
/// felhasználó NEM pont ezt a [depthBuzzCounter]-értéket zárta be.
///
/// A [dismissedAtCounter] a bezárás pillanatában rögzített számláló, vagy
/// `null`, ha még nem zártak be semmit. Mivel a számláló csak belépéskor és
/// új mélypontnál változik, a bezárás addig tart, amíg a víz nem sekélyedik
/// tovább — ez a ratchet UI-oldali párja: nem nyaggat, de újra szól, ha
/// romlik a helyzet.
bool isDepthAlertVisible({
  required double? depthAlertMeters,
  required int depthBuzzCounter,
  required int? dismissedAtCounter,
}) => depthAlertMeters != null && depthBuzzCounter != dismissedAtCounter;
