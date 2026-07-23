import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// A [RestrictedArea] négyzetének négy sarokpontja, körbejárási sorrendben
/// (ÉK → DK → DNy → ÉNy).
///
/// A domain a területet **középpont + oldalhossz** alakban tárolja, és
/// tudatosan nem talál ki sarokpontokat (a forrásadat is így érkezik).
/// A rajzoláshoz viszont poligon kell, ezért a sarkokat itt vezetjük le —
/// determinisztikusan, a `ProjectPositionAlongBearing` gömbi direkt
/// feladatával, nem síkbeli közelítéssel. Ez nem adat-kitalálás: ugyanaz
/// a négyzet, más ábrázolásban.
///
/// A sarok a középponttól a **fél átlóra** esik, 45°-os többszörösek
/// mentén: `oldalhossz / 2 * sqrt(2)`.
///
/// **Miért nem kör.** Egy 70 m oldalú négyzet köréírt köre a sarkoknál
/// ~41%-kal túlnyúlik, a beírt kör pedig épp a sarkokat hagyja ki. Egy
/// tiltott terület határának mindkét irányban hazudni rossz — a `Polygon`
/// pontosan azt a határt rajzolja, amit a katalógus állít.
///
/// **Miért itt és nem a domainben.** A domain már birtokolja a nehéz
/// részt (a gömbi vetítést); ez csak négy hívás fix irányszögekkel, egy
/// fogyasztóval. Ha a korridor-réteg (roadmap S3) is kérdezni fogja
/// („a hajón belül van-e a területen?"), akkor a geometria felkerül a
/// domainbe — addig ott fogyasztó nélküli, drift-veszélyes kód lenne.
List<LatLng> restrictedAreaOutline(RestrictedArea area) {
  const project = ProjectPositionAlongBearing();
  final halfDiagonal = Distance(
    meters: area.sideLength.meters / 2 * math.sqrt2,
  );
  return [
    for (final degrees in _cornerBearings)
      _toLatLng(
        project(
          from: area.position,
          bearing: Bearing.true_(degrees),
          distance: halfDiagonal,
        ),
      ),
  ];
}

/// A sarkok irányszögei a középpontból, körbejárási sorrendben.
const List<double> _cornerBearings = [45, 135, 225, 315];

LatLng _toLatLng(Coordinate c) => LatLng(c.latitude, c.longitude);
