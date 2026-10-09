import 'package:domain/src/value_objects/track_sample.dart';

/// A befejezett verseny rögzített pillanatképeit időrendi [TrackSample]
/// projekcióként szolgáltató kontraktus (ADR 0044 Addendum 4).
///
/// Szándékosan külön kontraktus a `RoundingSampleReader` mellett, nem annak
/// a bővítése: a detail-képernyő elemzésének mind a tizenhárom mező kell, a
/// track-összesítőnek három. A szűkebb szerződés teszi lehetővé, hogy az
/// implementáció a teljes `RaceSnapshot` visszaépítése nélkül, projekcióval
/// olvasson — ez a napló összesítőinek ANR-jét okozó költség gyökere.
///
/// Függvény-typedef (nem egytagú abstract class) a `one_member_abstracts`
/// lint miatt; az impl egy callable osztály.
typedef TrackSampleReader = Future<List<TrackSample>> Function(String raceId);
