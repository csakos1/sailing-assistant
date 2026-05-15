/// A `domain` package nyilvános API-ja.
///
/// Pure Dart, semmi Flutter — a domain réteg az NMEA mérésekből
/// kiszámolt vitorláshajózási intelligenciát tartalmazza: value
/// objektumok, entitások, use case-ek, és repository interfészek.
library;

export 'src/entities/mark.dart';
export 'src/value_objects/angle.dart';
export 'src/value_objects/bearing.dart';
export 'src/value_objects/coordinate.dart';
export 'src/value_objects/distance.dart';
export 'src/value_objects/speed.dart';
