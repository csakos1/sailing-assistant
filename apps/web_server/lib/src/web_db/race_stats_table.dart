import 'package:drift/drift.dart';

/// A versenyek statisztika-cache-e (ADR 0048 D4, D9 + Addendum 3 I2, I4,
/// ADR 0050 D5).
///
/// Telemetriás versenynek és trackes kézi versenynek van sora; a track
/// nélküli kézi verseny statjai beírt értékek. Az ablak fajtája `'official'`
/// vagy `'recording'`, a határai epoch-milliszekundumok: a sor csak akkor
/// érvényes, ha ezek pontosan egyeznek a várt ablakkal. Az irány fokban
/// áll, az égtájra képzés a válasz dolga.
///
/// Az osztály neve nem `RaceStats`, hogy ne ütközzön a szerződés
/// típusával; a tábla neve ettől még `race_stats`.
@DataClassName('RaceStatsRow')
class RaceStatsTable extends Table {
  @override
  String get tableName => 'race_stats';

  TextColumn get raceId => text()();
  TextColumn get windowKind => text()();
  IntColumn get windowStartMs => integer().named('window_start')();
  IntColumn get windowEndMs => integer().named('window_end')();
  RealColumn get distanceMeters => real().named('distance_m').nullable()();
  RealColumn get avgSpeedMps => real().nullable()();
  RealColumn get maxSpeedMps => real().nullable()();
  RealColumn get avgWindMps => real().nullable()();
  RealColumn get maxWindMps => real().nullable()();
  RealColumn get windDirDeg => real().nullable()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};

  @override
  List<String> get customConstraints => [
    "CHECK (window_kind IN ('official', 'recording'))",
  ];
}
