import 'package:domain/domain.dart';

/// Az égtáj magyar rövidítése (ADR 0048 D5): É, ÉÉK, … ÉÉNy.
///
/// Pontosan az Excel-napló jelölései, hogy a régi és az új adat ugyanúgy
/// olvasson. Nem ARB-kulcs, hanem rögzített rövidítés-készlet, mint a
/// formázók mértékegységei (ADR 0047 Addendum 5 F6, ismert i18n-adósság).
String compassPointLabel(CompassPoint point) => switch (point) {
  CompassPoint.north => 'É',
  CompassPoint.northNorthEast => 'ÉÉK',
  CompassPoint.northEast => 'ÉK',
  CompassPoint.eastNorthEast => 'KÉK',
  CompassPoint.east => 'K',
  CompassPoint.eastSouthEast => 'KDK',
  CompassPoint.southEast => 'DK',
  CompassPoint.southSouthEast => 'DDK',
  CompassPoint.south => 'D',
  CompassPoint.southSouthWest => 'DDNy',
  CompassPoint.southWest => 'DNy',
  CompassPoint.westSouthWest => 'NyDNy',
  CompassPoint.west => 'Ny',
  CompassPoint.westNorthWest => 'NyÉNy',
  CompassPoint.northWest => 'ÉNy',
  CompassPoint.northNorthWest => 'ÉÉNy',
};
