import 'package:domain/src/value_objects/polar_sample.dart';
import 'package:domain/src/value_objects/time_window.dart';

/// Egy verseny polár-mintáit időrendben szolgáltató kontraktus (ADR 0049
/// D13, Addendum 3 T1).
///
/// A [TimeWindow] `null` értéke a teljes rögzítést jelenti; különben csak
/// az ablakba eső minták jönnek (a határokat is beleértve).
///
/// Függvény-typedef a `WindSampleReader` mintájára: a telefonos és a régi
/// versenyek olvasója ugyanezt a típust adja.
typedef PolarSampleReader =
    Future<List<PolarSample>> Function(String raceId, TimeWindow? window);
