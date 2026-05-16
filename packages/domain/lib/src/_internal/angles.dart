import 'dart:math' as math;

/// Fok → radián konverzió.
///
/// Library-internal helper a domain rétegen belül. A trigonometriai
/// számítások (bearing, haversine, wind-shift trend, WMM) közös
/// konverziós pontja, hogy a `pi/180` faktor ne duplikálódjon
/// különböző numerikus konstans-alakokban (pl. `0.0174533`).
///
/// **Nincs a public barrel-ben** (`domain.dart`) — csak within-package
/// `src/_internal/` import elérhető.
double degreesToRadians(double degrees) => degrees * math.pi / 180;

/// Radián → fok konverzió. Lásd [degreesToRadians] a részletekért.
double radiansToDegrees(double radians) => radians * 180 / math.pi;
