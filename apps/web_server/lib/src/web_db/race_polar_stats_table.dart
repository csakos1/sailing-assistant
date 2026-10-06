import 'package:drift/drift.dart';

/// A versenyek polár-cache-ének fő sora (ADR 0049 D10, Addendum 4 U4).
///
/// Az ablak a `race_stats`-éval azonos alakú; a sor csak akkor friss, ha
/// az ablaka a várt ablak, és a [referenceFingerprint] a mostani polár és
/// korrekció ujjlenyomata. A sor akkor is létrejön, ha a versenynek nincs
/// polár-mintája (mért idő 0): így a „számolva" és a „nincs számolva"
/// különválik.
@DataClassName('RacePolarStatsRow')
class RacePolarStatsTable extends Table {
  @override
  String get tableName => 'race_polar_stats';

  TextColumn get raceId => text()();
  TextColumn get windowKind => text()();
  IntColumn get windowStartMs => integer().named('window_start')();
  IntColumn get windowEndMs => integer().named('window_end')();
  TextColumn get referenceFingerprint => text()();
  IntColumn get measuredSeconds => integer()();
  RealColumn get pctSecondsSum => real()();
  RealColumn get twsMpsSecondsSum => real()();
  RealColumn get bestFivePct => real().nullable()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};

  @override
  List<String> get customConstraints => [
    "CHECK (window_kind IN ('official', 'recording'))",
  ];
}
