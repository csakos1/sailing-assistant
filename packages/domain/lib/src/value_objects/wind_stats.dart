import 'package:meta/meta.dart';

/// Egy verseny szél-statisztikája (ADR 0048 D5).
///
/// A `SummarizeWind` állítja elő. A `TrackStats`-hoz hasonlóan a `null`
/// mindenhol „nincs adat", nem nulla.
@immutable
class WindStats {
  /// Minden mező opcionális; a `null` az adott statisztika hiányát jelzi.
  const WindStats({this.avgWindMps, this.maxWindMps, this.directionDeg});

  /// A valós szélsebesség számtani átlaga m/s-ben.
  final double? avgWindMps;

  /// A legnagyobb valós szélsebesség m/s-ben, tüske-szűrve: az 5 mintás
  /// csúszó mediánok maximuma (ADR 0048 Addendum 5 L3). A
  /// `TrackStats.maxSpeedMps` ezzel szemben nyers.
  final double? maxWindMps;

  /// Az uralkodó valós szélirány fokban, `[0, 360)` tartományban: a
  /// minták körkörös átlaga. `null`, ha nincs irány-minta, vagy az irányok
  /// kioltják egymást.
  final double? directionDeg;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindStats &&
          other.avgWindMps == avgWindMps &&
          other.maxWindMps == maxWindMps &&
          other.directionDeg == directionDeg;

  @override
  int get hashCode => Object.hash(avgWindMps, maxWindMps, directionDeg);

  @override
  String toString() =>
      'WindStats(avgWindMps: $avgWindMps, maxWindMps: $maxWindMps, '
      'directionDeg: $directionDeg)';
}
