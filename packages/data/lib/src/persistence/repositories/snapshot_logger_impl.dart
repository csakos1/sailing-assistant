import 'dart:convert';
import 'dart:developer' as developer;

import 'package:data/src/engine/race_snapshot.dart';
import 'package:data/src/engine/snapshot_logger.dart';
import 'package:data/src/persistence/app_database.dart';

/// A `SnapshotLogger` Drift-alapú implementációja (ADR 0022).
///
/// Race-enként az 1 Hz-es `RaceSnapshot`-ot a `snapshot_logs` táblába írja,
/// `jsonEncode(snapshot.toJson())` blobként. **Nincs buffer**: 1 sor/mp
/// triviális a WAL-on (a telemetria 100/1s bufferje itt felesleges). A [log]
/// internál try/catch-csel véd: a vízen futó engine snapshot-streamjét egy
/// DB-hiba sem szakíthatja meg (defenzív elv) — ezért az engine `unawaited`
/// hívással is biztonsággal hívhatja.
class SnapshotLoggerImpl implements SnapshotLogger {
  /// A `database` a cél Drift adatbázis — az engine-úton a másodlagos,
  /// WAL-módú `AppDatabase.secondary()` kapcsolat (ADR 0017 D6 / 0022 D3).
  SnapshotLoggerImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> log(String raceId, RaceSnapshot snapshot) async {
    try {
      await _database
          .into(_database.snapshotLogs)
          .insert(
            SnapshotLogsCompanion.insert(
              raceId: raceId,
              timestamp: snapshot.tickTime,
              snapshotJson: jsonEncode(snapshot.toJson()),
            ),
          );
    } on Object catch (error) {
      // Defenzív: a DB-hiba nem buborékolhat fel a snapshot-streamre.
      developer.log(
        'snapshot-log write failed',
        name: 'SnapshotLogger',
        error: error,
      );
    }
  }

  @override
  Future<void> dispose() async {
    // Buffer nincs, így nincs záró flush; a kapcsolatot a composition
    // root zárja.
  }
}
