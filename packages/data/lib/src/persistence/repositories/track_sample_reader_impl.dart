import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/extensions/json1.dart';

/// A [TrackSampleReader] Drift-alapú implementációja (ADR 0044 Addendum 4).
///
/// Ugyanazt a `snapshot_logs` táblát olvassa, mint a `RoundingSampleReader`,
/// de a tárolt JSON-t **nem** építi vissza `RaceSnapshot`-tá: a három
/// szükséges mennyiséget az SQLite `json1` kiterjesztése vonja ki, még a
/// C-oldalon. Így soronként három szám kel át a Dart-határon egy teljes
/// objektum-gráf helyett — a JSON-szöveg be sem lép a Dart-heap-be.
///
/// A séma változatlan: a tábla az ADR 0022 író-oldalból már létezik, és a
/// `snapshot_log_race_time` index szolgálja ki a szűrést és a rendezést.
///
/// A rendezés a helyesség része, nem kényelem: az úthossz szomszédos
/// pozíciókat láncol, tehát a sorrend a mért távolságot befolyásolja.
class TrackSampleReaderImpl {
  /// A `database` a Drift adatbázis (az elsődleges UI-kapcsolat).
  TrackSampleReaderImpl(this._database);

  final AppDatabase _database;

  /// A `raceId` versenyhez tartozó minták időrendben; üres lista, ha nincs
  /// rögzített `snapshot_logs` ehhez a versenyhez.
  Future<List<TrackSample>> call(String raceId) async {
    final logs = _database.snapshotLogs;
    final sogMps = logs.snapshotJson.jsonExtract<double>(_sogPath);
    final latDeg = logs.snapshotJson.jsonExtract<double>(_latPath);
    final lonDeg = logs.snapshotJson.jsonExtract<double>(_lonPath);

    final query = _database.selectOnly(logs)
      ..addColumns([sogMps, latDeg, lonDeg])
      ..where(logs.raceId.equals(raceId))
      ..orderBy([OrderingTerm.asc(logs.timestamp)]);

    final rows = await query.get();
    return [
      for (final row in rows)
        _ProjectedTrackSample(
          sogMps: row.read(sogMps),
          latDeg: row.read(latDeg),
          lonDeg: row.read(lonDeg),
        ),
    ];
  }
}

// Az útvonalak a `RaceSnapshot.toJson` alakjából: a sebesség NYERS double
// (a `_speedToJson` a m/s-ot adja, nem beágyazott mapot), a pozíció pedig
// `lat`/`lon` kulcsú map — nem `latitude`/`longitude`.
const _sogPath = r'$.boatState.speedOverGround';
const _latPath = r'$.boatState.position.lat';
const _lonPath = r'$.boatState.position.lon';

// A projekcióból épített minta. Hiányzó pozíciónál a JSON-ban `null` áll, a
// `json_extract` NULL-t ad, a mező `null` lesz — pontosan az a szemantika,
// amit a `RoundingSample` lat/lon doc-ja is leír.
class _ProjectedTrackSample implements TrackSample {
  const _ProjectedTrackSample({this.sogMps, this.latDeg, this.lonDeg});

  @override
  final double? sogMps;

  @override
  final double? latDeg;

  @override
  final double? lonDeg;
}
