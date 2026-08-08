import 'package:domain/src/value_objects/track_stats.dart';

/// A verseny materializált track-statisztikáját olvasó kontraktus
/// (ADR 0044 Addendum 4).
///
/// A visszaadott `null` NEM hiba, hanem a lusta feltöltés jelzése: a
/// versenyhez még nincs gyorsítótár-sor, tehát a hívó számol és ír. Ez
/// megkülönböztetendő a `TrackStats` mezőinek `null`-jától, ami már a
/// kiszámolt eredmény: „megnéztük, de nincs rá adat".
///
/// A kontraktus szándékosan `TrackStats`-ot ad vissza, nem a teljes tárolt
/// sort. A `sampleCount` és a `computedAt` diagnosztika, amit egyetlen
/// fogyasztó sem olvas — a szűkebb szerződés kevesebbet ígér, és később
/// kevesebbet is kell megtartania.
///
/// Függvény-typedef (nem egytagú abstract class) a `one_member_abstracts`
/// lint miatt; az impl egy metódus-tear-off.
typedef RaceTrackStatsReader = Future<TrackStats?> Function(String raceId);
