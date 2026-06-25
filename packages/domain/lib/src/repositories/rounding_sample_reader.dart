import 'package:domain/src/value_objects/rounding_sample.dart';

/// A befejezett verseny rögzített pillanatképeit időrendi [RoundingSample]
/// read-modellként szolgáltató kontraktus (ADR 0034 D4).
///
/// A `data` réteg olvassa a `snapshot_logs`-ot és mappel; az application a
/// `RoundingSampleReader`-t injektálja (DIP), nem a konkrét Drift-olvasót. A
/// `RaceSnapshot` data-DTO nem szivárog ki — a kontraktus csak primitív
/// [RoundingSample]-öket ad vissza, amiket az `AnalyzeRoundings` use case
/// fogyaszt. Függvény-typedef (nem egytagú abstract class) a
/// `one_member_abstracts` lint miatt; az impl egy callable osztály.
typedef RoundingSampleReader =
    Future<List<RoundingSample>> Function(String raceId);
