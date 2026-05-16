import 'dart:math' as math;

import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:meta/meta.dart';

/// Két koordináta közötti initial bearing (forward azimuth) számítása
/// gömbi geometriával.
///
/// A standard navigációs képletet `atan2(y, x)` alapon számolja, ahol
/// `y` és `x` a gömbi háromszögelés transzformált értékei. A bearing
/// `from`-ból `to` felé induló nagykör (great circle) irányát adja
/// meg [BearingReference.trueNorth]-hoz képest, fokban `[0, 360)`
/// tartományban.
///
/// A Balaton méretei (max ~80 km) mellett a kezdeti és a haladás
/// közben változó nagykör-bearing gyakorlatilag egybeesik (a rhumb
/// line vs great circle különbség elhanyagolható), így az UI-nak
/// elegendő ez az egyetlen érték.
///
/// **Pure use case**: nincs állapot, idempotens. Mindig
/// [BearingReference.trueNorth] referenciájú [Bearing]-et ad — a
/// mágneses irányváltáshoz a `GeomagneticService` declination-ja
/// szükséges, ami külön use case szintjén történik, nem itt.
///
/// **Edge case-ek.** A `from == to` esetén `atan2(0, 0) = 0` (IEEE 754
/// konvenció), így az eredmény `0°` (north). Konvencionális választás
/// — UI szinten irreleváns, mert ha a hajó pontosan a bóyán van, a
/// downstream mark-rounding detektor már `roundedAt`-et állít, és a
/// `MarkPrediction` az új aktív bóyára vált.
///
/// **Antimeridian (180°-os hosszúság) crossing**: a képlet helyesen
/// kezeli, mert a `dLon` előjeles és a `cos` / `sin` periodikus.
@immutable
class CalculateBearingToMark {
  /// Const ctor — a use case stateless, példány-egyenlőség nem
  /// releváns; const-elve egyetlen instance is elég.
  const CalculateBearingToMark();

  /// Initial bearing a [from] pontból a [to] pont felé,
  /// [BearingReference.trueNorth]-hoz képest. Részletek a class-doc-ban.
  Bearing call(Coordinate from, Coordinate to) {
    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLon = _toRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final thetaRad = math.atan2(y, x);

    // atan2 (-pi, +pi] → fok, majd modulo 360-tal [0, 360) tartományra.
    final degrees = (_toDeg(thetaRad) + 360) % 360;
    return Bearing.true_(degrees);
  }

  static double _toRad(double degrees) => degrees * math.pi / 180;
  static double _toDeg(double radians) => radians * 180 / math.pi;
}
