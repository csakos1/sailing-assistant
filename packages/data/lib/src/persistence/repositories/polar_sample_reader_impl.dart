import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';

/// A [PolarSampleReader] Drift-alapú implementációja (ADR 0049 D13,
/// Addendum 3 T1).
///
/// A `WindSampleReaderImpl` mintájára projekcióval olvas: a `snapshot_logs`
/// JSON-jából az SQLite `json1` kiterjesztése vonja ki a valós szélszöget,
/// a valós szélsebességet és a vízsebességet, így a teljes `RaceSnapshot`
/// nem épül vissza. Az időbélyeg a `timestamp` oszlopból jön; a telefon
/// 1 Hz-es pillanatképe egy másodpercet ér.
class PolarSampleReaderImpl {
  /// A `database` a Drift adatbázis.
  PolarSampleReaderImpl(this._database);

  final AppDatabase _database;

  /// A `raceId` versenyhez tartozó minták időrendben, a [window]-ba esők
  /// (a határokat is beleértve); `null` ablak a teljes rögzítés.
  Future<List<PolarSample>> call(String raceId, TimeWindow? window) async {
    final logs = _database.snapshotLogs;
    final twaDeg = logs.snapshotJson.jsonExtract<double>(_twaPath);
    final twsMps = logs.snapshotJson.jsonExtract<double>(_twsPath);
    final stwMps = logs.snapshotJson.jsonExtract<double>(_stwPath);

    var condition = logs.raceId.equals(raceId);
    if (window != null) {
      condition &= logs.timestamp.isBetweenValues(window.start, window.end);
    }

    final query = _database.selectOnly(logs)
      ..addColumns([logs.timestamp, twaDeg, twsMps, stwMps])
      ..where(condition)
      ..orderBy([OrderingTerm.asc(logs.timestamp)]);

    final rows = await query.get();
    return [
      for (final row in rows)
        PolarSample(
          // A `!` biztonságos: a `timestamp` oszlop NOT NULL.
          timestamp: row.read(logs.timestamp)!,
          twaDeg: row.read(twaDeg),
          twsMps: row.read(twsMps),
          stwMps: row.read(stwMps),
        ),
    ];
  }
}

// Az útvonalak a `RaceSnapshot.toJson` alakjából: a szög és a sebességek
// nyers double-ök (fok, illetve m/s). Hiányzó szélnél az egész `wind`
// mező `null`, a `json_extract` ilyenkor NULL-t ad.
const _twaPath = r'$.wind.trueAngleWater';
const _twsPath = r'$.wind.trueSpeedWater';
const _stwPath = r'$.boatState.speedThroughWater';
