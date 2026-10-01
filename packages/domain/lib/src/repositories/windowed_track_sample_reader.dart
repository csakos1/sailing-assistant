import 'package:domain/src/value_objects/time_window.dart';
import 'package:domain/src/value_objects/track_sample.dart';

/// A `TrackSampleReader` időablakos változata (ADR 0048 D4).
///
/// Külön kontraktus, nem a meglévő bővítése: a phone és a meglévő tesztek
/// fake-jei a `TrackSampleReader` egy-paraméteres alakjára épülnek, és egy
/// új, opcionális paraméter minden ilyen hívási helyet eltörne (OCP). A
/// [TimeWindow] `null` értéke a teljes rögzítést jelenti.
typedef WindowedTrackSampleReader =
    Future<List<TrackSample>> Function(String raceId, TimeWindow? window);
