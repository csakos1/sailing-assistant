/// A `domain` package nyilvános API-ja.
///
/// Pure Dart, semmi Flutter — a domain réteg az NMEA mérésekből
/// kiszámolt vitorláshajózási intelligenciát tartalmazza: value
/// objektumok, entitások, use case-ek, és repository interfészek.
library;

export 'src/entities/boat_state.dart';
export 'src/entities/eta_source.dart';
export 'src/entities/mark.dart';
export 'src/entities/mark_prediction.dart';
export 'src/entities/race.dart';
export 'src/entities/race_status.dart';
export 'src/entities/wind_data.dart';
export 'src/entities/wind_observation.dart';
export 'src/entities/wind_shift_confidence.dart';
export 'src/entities/wind_shift_trend.dart';
export 'src/use_cases/calculate_bearing_to_mark.dart';
export 'src/use_cases/calculate_course_correction.dart';
export 'src/use_cases/calculate_distance_to_mark.dart';
export 'src/value_objects/angle.dart';
export 'src/value_objects/bearing.dart';
export 'src/value_objects/coordinate.dart';
export 'src/value_objects/distance.dart';
export 'src/value_objects/speed.dart';
