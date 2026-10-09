// Csomó ↔ m/s (ADR 0048 Addendum 4 K11). A kézi verseny mezői csomóban és
// kilométerben, a szerződés SI-ben dolgozik.

/// Egy csomó m/s-ben: 1852 m óránként.
const double metersPerSecondPerKnot = 1852 / 3600;

/// Csomó → m/s.
double knotsToMetersPerSecond(double knots) => knots * metersPerSecondPerKnot;

/// m/s → csomó.
double metersPerSecondToKnots(double metersPerSecond) =>
    metersPerSecond / metersPerSecondPerKnot;
