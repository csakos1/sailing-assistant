import 'package:drift/drift.dart';

/// A versenyek 2 csomós szélvödrei a rang számításához (ADR 0049 D9, D10,
/// Addendum 4 U4).
@DataClassName('RacePolarBucketRow')
class RacePolarBucketsTable extends Table {
  @override
  String get tableName => 'race_polar_buckets';

  TextColumn get raceId => text()();
  IntColumn get twsBucket => integer()();
  IntColumn get seconds => integer()();
  RealColumn get pctSecondsSum => real()();

  @override
  Set<Column> get primaryKey => {raceId, twsBucket};
}
