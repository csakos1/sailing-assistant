/// A szélrózsa 16 iránya (ADR 0048 D5).
///
/// A sorrend az iránytűé, északtól az óramutató járásával: az [index] az
/// irány sorszáma, a középvonala `index × 22,5°`. A kézi verseny ezt az
/// indexet tárolja, a telemetriás verseny számolt fokértéke pedig a
/// [CompassPoint.fromDegrees]-szel képződik rá, így a táblázat egységes.
///
/// A magyar felirat (É, ÉÉK, … ÉÉNy) a megjelenítés dolga, nem a domainé.
enum CompassPoint {
  /// É
  north,

  /// ÉÉK
  northNorthEast,

  /// ÉK
  northEast,

  /// KÉK
  eastNorthEast,

  /// K
  east,

  /// KDK
  eastSouthEast,

  /// DK
  southEast,

  /// DDK
  southSouthEast,

  /// D
  south,

  /// DDNy
  southSouthWest,

  /// DNy
  southWest,

  /// NyDNy
  westSouthWest,

  /// Ny
  west,

  /// NyÉNy
  westNorthWest,

  /// ÉNy
  northWest,

  /// ÉÉNy
  northNorthWest
  ;

  /// Egy szektor szélessége fokban.
  static const double sectorDegrees = 360 / 16;

  /// A [degrees] irányhoz legközelebbi égtáj.
  ///
  /// Bármilyen véges fokértéket elfogad (negatívat és 360 fölöttit is), és
  /// a teljes körre normálja. A szektorhatár (pl. 11,25°) a következő,
  /// óramutató szerinti égtájhoz tartozik.
  static CompassPoint fromDegrees(double degrees) {
    final normalized = degrees % 360;
    final index =
        ((normalized + sectorDegrees / 2) / sectorDegrees).floor() % 16;
    return values[index];
  }

  /// Az égtáj középvonala fokban.
  double get centerDegrees => index * sectorDegrees;
}
