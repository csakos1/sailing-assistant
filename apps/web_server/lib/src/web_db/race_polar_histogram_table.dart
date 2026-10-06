import 'package:drift/drift.dart';

/// A versenyek %-hisztogramja: rés → másodperc (ADR 0049 D10, Addendum 4
/// U4). Ritka tárolás: csak a nem üres rések.
@DataClassName('RacePolarHistogramRow')
class RacePolarHistogramTable extends Table {
  @override
  String get tableName => 'race_polar_histogram';

  TextColumn get raceId => text()();
  IntColumn get pctBin => integer()();
  IntColumn get seconds => integer()();

  @override
  Set<Column> get primaryKey => {raceId, pctBin};
}
