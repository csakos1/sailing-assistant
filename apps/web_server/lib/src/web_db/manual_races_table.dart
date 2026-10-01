import 'package:drift/drift.dart';

/// A telemetria nélküli, kézi versenyek (ADR 0048 D2, D9 + Addendum 3
/// I2).
///
/// A nap `YYYY-MM-DD` szöveg (naptári nap, zóna nélkül), az égtáj a
/// `CompassPoint` indexe (0–15). A statok SI-egységben.
///
/// Row-class: `ManualRaceRow`.
@DataClassName('ManualRaceRow')
class ManualRaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get date => text()();
  RealColumn get distanceMeters => real().named('distance_m').nullable()();
  RealColumn get maxSpeedMps => real().nullable()();
  RealColumn get avgWindMps => real().nullable()();
  RealColumn get maxWindMps => real().nullable()();
  IntColumn get windPoint => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (wind_point IS NULL OR wind_point BETWEEN 0 AND 15)',
  ];
}
