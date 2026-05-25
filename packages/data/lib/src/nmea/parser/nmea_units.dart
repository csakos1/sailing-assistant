// NMEA 0183 wire-egységek átváltása a domain SI-egységére (m/s).
//
// A 0183 sebesség-mezők csomóban (N) vagy km/h-ban (K) érkeznek; a domain
// Speed tisztán m/s-ben tárol (a csomó-megjelenítés a presentation rétegé).
// A dekóderek (MWV, RMC, VTG, VHW) ezt a két helpert hívják, hogy a
// konverziós konstans egyetlen helyen éljen.

/// 1 csomó = 1 tengeri mérföld / óra = 1852 m / 3600 s.
const double _metersPerSecondPerKnot = 1852 / 3600;

/// 1 km/h = 1000 m / 3600 s.
const double _metersPerSecondPerKmh = 1000 / 3600;

/// A [knots] csomó-értéket m/s-re váltja.
double metersPerSecondFromKnots(double knots) =>
    knots * _metersPerSecondPerKnot;

/// A [kmh] km/h-értéket m/s-re váltja.
double metersPerSecondFromKmh(double kmh) => kmh * _metersPerSecondPerKmh;
