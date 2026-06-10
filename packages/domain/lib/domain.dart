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
export 'src/entities/twa_prediction.dart';
export 'src/entities/twd_estimate.dart';
export 'src/entities/twd_quality.dart';
export 'src/entities/wind_data.dart';
export 'src/entities/wind_observation.dart';
export 'src/entities/wind_shift_confidence.dart';
export 'src/entities/wind_shift_trend.dart';
export 'src/projection/boat_state_reducer.dart';
export 'src/projection/wind_history_reducer.dart';
export 'src/repositories/connection_status.dart';
export 'src/repositories/domain_event.dart';
export 'src/repositories/nmea_stream.dart';
export 'src/repositories/race_repository.dart';
export 'src/repositories/settings_repository.dart';
export 'src/repositories/telemetry_logger.dart';
export 'src/use_cases/calculate_bearing_to_mark.dart';
export 'src/use_cases/calculate_course_correction.dart';
export 'src/use_cases/calculate_distance_to_mark.dart';
export 'src/use_cases/calculate_eta_to_mark.dart';
export 'src/use_cases/calculate_wind_shift_trend.dart';
export 'src/use_cases/compute_mark_prediction.dart';
export 'src/use_cases/derive_true_wind_direction.dart';
export 'src/use_cases/estimate_prediction_confidence.dart';
export 'src/use_cases/evaluate_warnings.dart';
export 'src/use_cases/mark_rounding_detector.dart';
export 'src/use_cases/predict_twa_at_mark.dart';
export 'src/value_objects/angle.dart';
export 'src/value_objects/bearing.dart';
export 'src/value_objects/coordinate.dart';
export 'src/value_objects/distance.dart';
export 'src/value_objects/speed.dart';
export 'src/value_objects/telemetry_record.dart';
export 'src/warnings/warning.dart';
export 'src/warnings/warning_severity.dart';
