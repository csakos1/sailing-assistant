import 'package:data/src/persistence/tables/races_table.dart';
import 'package:drift/drift.dart';

/// Kiszámolt-érték telemetria: race-enként az 1 Hz-es `RaceSnapshot`
/// JSON-blobja post-race elemzéshez (ADR 0022). A nyers NMEA-mondatokat
/// a `TelemetryRecords` viszi; ez a tábla az app *kiszámolt* outputját
/// tárolja (köv-bója-TWA predikció, konfidencia, TWD-állapot, bearing,
/// ETA, korrekció — a teljes snapshot). A `(raceId, timestamp)` index a
/// post-race lekérdezéshez; FK-cascade a `Races`-re. Row-class:
/// `SnapshotLogRow`.
@DataClassName('SnapshotLogRow')
@TableIndex(name: 'snapshot_log_race_time', columns: {#raceId, #timestamp})
class SnapshotLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get snapshotJson => text()();
}
