/// Hiányzó érték jele a post-race felületeken.
///
/// Szándékosan nem nulla és nem üres string: a hiányzó mérés nem
/// ugyanaz, mint a nulla mért érték.
const String missingValueLabel = '—';

/// Egy m/s-ben mért sebesség csomóban, egy tizedesre (`5.3 kn`), vagy a
/// hiányjel.
String formatKnots(double? metersPerSecond) {
  if (metersPerSecond == null) return missingValueLabel;
  const mpsToKnots = 1.943844;
  return '${(metersPerSecond * mpsToKnots).toStringAsFixed(1)} kn';
}

/// Egy méterben mért távolság (`1.2 km` vagy `840 m`), vagy a hiányjel.
///
/// Ezer méter alatt méterre vált: egy 840 méteres pályaszakasz `0.8 km`
/// alakban elveszítené a felbontását.
String formatDistance(double? meters) {
  if (meters == null) return missingValueLabel;
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${meters.round()} m';
}

/// Egy mért érték a számjegyeire és a mértékegységére bontva.
///
/// A stat-cella a kettőt **két külön tipográfia-fokozattal** rajzolja (ADR
/// 0044 D29), tehát egyetlen stringként nem használható. A `value` magyar
/// tizedesvesszőt visz, a `unit` sosem kerül bele.
typedef MeasuredValue = ({String value, String unit});

/// Egy m/s-ben mért sebesség csomóban, egy tizedesre (`7,4` + `kn`).
///
/// Hiányzó mérésnél a hiányjel áll az érték helyén, és a mértékegység
/// **elmarad**: egy `—` mellett a `kn` azt sugallná, hogy mértünk valamit.
MeasuredValue measureKnots(double? metersPerSecond) {
  if (metersPerSecond == null) {
    return (value: missingValueLabel, unit: '');
  }
  const mpsToKnots = 1.943844;
  return (
    value: _withDecimalComma(metersPerSecond * mpsToKnots, 1),
    unit: 'kn',
  );
}

/// Egy méterben mért távolság (`24,6` + `km`, vagy `840` + `m`).
///
/// Ezer méter alatt méterre vált, tizedes nélkül: egy 840 méteres szakasz
/// `0,8 km` alakban elveszítené a felbontását.
MeasuredValue measureDistance(double? meters) {
  if (meters == null) {
    return (value: missingValueLabel, unit: '');
  }
  if (meters >= 1000) {
    return (value: _withDecimalComma(meters / 1000, 1), unit: 'km');
  }
  return (value: '${meters.round()}', unit: 'm');
}

// A magyar tizedesvessző: a formázott szám pontját cseréli. A `toString`
// mindig pontot ad, a lokalizált formázó pedig ehhez a két értékhez
// aránytalan lenne (nincs csoporthatároló és nincs nyelvi változat).
String _withDecimalComma(double value, int digits) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');
