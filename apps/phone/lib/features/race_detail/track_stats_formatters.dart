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
