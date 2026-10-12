import 'package:data/src/persistence/app_database.dart';
import 'package:drift/drift.dart';

/// A `LastRecordingReader` Drift-alapú implementációja (ADR 0054 E3): egy
/// verseny legutóbbi `snapshot_logs` sorának ideje.
///
/// A `snapshot_log_race_time` index (`raceId`, `timestamp`) miatt a `max`
/// egyetlen index-keresés, a JSON nem bomlik ki. A pillanatkép-log az engine
/// felvételének jele: csak `active` verseny alatt íródik (ADR 0054 D3).
class LastRecordingReaderImpl {
  /// A `database` a Drift adatbázis (az elsődleges UI-kapcsolat).
  LastRecordingReaderImpl(this._database);

  final AppDatabase _database;

  /// A `raceId` verseny legutóbbi rögzített pillanatképének ideje (UTC),
  /// vagy `null`, ha nincs felvétel.
  Future<DateTime?> call(String raceId) async {
    final logs = _database.snapshotLogs;
    final latest = logs.timestamp.max();
    final query = _database.selectOnly(logs)
      ..addColumns([latest])
      ..where(logs.raceId.equals(raceId));
    final row = await query.getSingle();
    // A Drift a DateTime-ot helyi időként adja vissza (§5 5.).
    return row.read(latest)?.toUtc();
  }
}
