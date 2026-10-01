import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';

/// A [WindSampleReader] Drift-alapú implementációja (ADR 0048 D5).
///
/// A `TrackSampleReaderImpl` mintájára projekcióval olvas: a `snapshot_logs`
/// JSON-jából az SQLite `json1` kiterjesztése vonja ki a valós szél
/// sebességét és irányát, így a teljes `RaceSnapshot` nem épül vissza.
///
/// Az irány csak **földrajzi** referenciával kerül át. A `Bearing` JSON-ja a
/// referenciát is hordozza; mágneses irányt deklináció nélkül nem lehet
/// földrajzira váltani, és egy kevert átlag csendben elcsúszna. A mágneses
/// minta ezért irány nélküli mintaként jön (a sebessége megmarad).
class WindSampleReaderImpl {
  /// A `database` a Drift adatbázis.
  WindSampleReaderImpl(this._database);

  final AppDatabase _database;

  /// A `raceId` versenyhez tartozó minták időrendben, a [window]-ba esők
  /// (a határokat is beleértve); `null` ablak a teljes rögzítés.
  Future<List<WindSample>> call(String raceId, TimeWindow? window) async {
    final logs = _database.snapshotLogs;
    final twsMps = logs.snapshotJson.jsonExtract<double>(_twsPath);
    final twdDeg = logs.snapshotJson.jsonExtract<double>(_twdDegPath);
    final twdRef = logs.snapshotJson.jsonExtract<String>(_twdRefPath);

    var condition = logs.raceId.equals(raceId);
    if (window != null) {
      condition &= logs.timestamp.isBetweenValues(window.start, window.end);
    }

    final query = _database.selectOnly(logs)
      ..addColumns([twsMps, twdDeg, twdRef])
      ..where(condition)
      ..orderBy([OrderingTerm.asc(logs.timestamp)]);

    final rows = await query.get();
    return [
      for (final row in rows)
        _ProjectedWindSample(
          twsMps: row.read(twsMps),
          twdDeg: row.read(twdRef) == _trueNorth ? row.read(twdDeg) : null,
        ),
    ];
  }
}

// Az útvonalak a `RaceSnapshot.toJson` alakjából: a sebesség nyers double
// (m/s), az irány `deg`/`ref` kulcsú map. Hiányzó szélnél az egész `wind`
// mező `null`, a `json_extract` ilyenkor NULL-t ad.
const _twsPath = r'$.wind.trueSpeedWater';
const _twdDegPath = r'$.wind.trueDirectionGround.deg';
const _twdRefPath = r'$.wind.trueDirectionGround.ref';

// A `BearingReference.trueNorth` neve, ahogy a `_bearingToJson` írja.
const _trueNorth = 'trueNorth';

class _ProjectedWindSample implements WindSample {
  const _ProjectedWindSample({this.twsMps, this.twdDeg});

  @override
  final double? twsMps;

  @override
  final double? twdDeg;
}
