/// Library-internal helper: 360°-os wrap-around-okat elsimít egy
/// szöglistán, hogy az eredmény monoton folytatható legyen.
///
/// Wind-shift trend kontextusban (ARCHITECTURE.md 7.4) a TWD minták
/// `[0, 360)` tartományban érkeznek, és a 359° → 1° átmenet egy
/// +2°-os shift-et jelez, NEM -358°-osat. Az algoritmus a szomszédos
/// **eredeti** (nem unwrap-elt) minták közti különbséget vizsgálja:
///
/// - `raw > 180` → counterclockwise wrap, kumulált offset -= 360
/// - `raw < -180` → clockwise wrap, kumulált offset += 360
///
/// Az aktuális minta unwrap-elt értéke `degrees[i] + cumulativeOffset`.
/// Az első elem mindig változatlan (offset 0).
///
/// **180° ambivalencia — szigorú küszöb (`>` és `<`, NEM `>=` és `<=`).**
/// A pontos ±180°-os ugrás nem trigger-el wrap-detektet. Wind-shift
/// use case-ben (1/min downsampling) egy minta alatti 180°-os
/// TWD-ugrás gyakorlatilag lehetetlen; ha mégis előfordul, a 7.4
/// regresszió r²-je alacsony lesz → low confidence.
///
/// **NaN / ±infinity input.** Library-internal helper-kontrakt szerint
/// a hívó (7.4 use case) felelős a validitásért. NaN/±inf esetén a
/// kumulált offset propagálódik, az output ugyanúgy NaN-os lesz.
List<double> unwrapAngles(List<double> degrees) {
  if (degrees.length < 2) {
    return List.of(degrees);
  }

  final result = <double>[degrees.first];
  var cumulativeOffset = 0.0;

  for (var i = 1; i < degrees.length; i++) {
    final raw = degrees[i] - degrees[i - 1];
    if (raw > 180) {
      cumulativeOffset -= 360;
    } else if (raw < -180) {
      cumulativeOffset += 360;
    }
    result.add(degrees[i] + cumulativeOffset);
  }

  return result;
}
