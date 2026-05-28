import 'package:data/src/persistence/tables/races_table.dart';
import 'package:drift/drift.dart';

/// Post-race telemetria: race-enként a nyers `$…*XX` 0183 mondatok (ADR
/// 0008, D1/D9). A `decodedJson` v1-ben null — post-race re-decode. A
/// `(raceId, timestamp)` index a post-race lekérdezéshez. Row-class:
/// `TelemetryRow`.
@DataClassName('TelemetryRow')
@TableIndex(name: 'telemetry_race_time', columns: {#raceId, #timestamp})
class TelemetryRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get rawSentence => text()();
  TextColumn get decodedJson => text().nullable()();
}
