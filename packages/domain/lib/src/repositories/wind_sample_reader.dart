import 'package:domain/src/value_objects/time_window.dart';
import 'package:domain/src/value_objects/wind_sample.dart';

/// Egy befejezett verseny rögzített pillanatképeit időrendi [WindSample]
/// projekcióként szolgáltató kontraktus (ADR 0048 D4, D5).
///
/// A [TimeWindow] `null` értéke a teljes rögzítést jelenti; különben csak
/// az ablakba eső minták jönnek (a határokat is beleértve).
///
/// Függvény-typedef a `TrackSampleReader` mintájára.
typedef WindSampleReader =
    Future<List<WindSample>> Function(String raceId, TimeWindow? window);
