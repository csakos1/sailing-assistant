import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// A `race_track_stats` tábla Drift-alapú olvasó-írója (ADR 0044
/// Addendum 4).
///
/// Két domain-kontraktust szolgál ki — `RaceTrackStatsReader` és
/// `RaceTrackStatsWriter` —, amelyeket a providerek metódus-tear-offként
/// vesznek át; az application így továbbra sem látja ezt az osztályt (DIP).
/// Egy osztály, mert egyetlen tábla perzisztenciája egyetlen felelősség.
///
/// Az osztály kizárólag fordít: a `TrackStats` a `SummarizeTrack`
/// eredménye, a számolás nem itt történik, és geometria nem kerül SQL-be
/// (ADR 0044 Addendum 4).
class RaceTrackStatsRepositoryImpl {
  /// A `database` a cél Drift adatbázis.
  RaceTrackStatsRepositoryImpl(this._database);

  final AppDatabase _database;

  /// A versenyhez tartozó statisztika, vagy `null`, ha még nincs sor.
  ///
  /// A `raceId` a tábla elsődleges kulcsa, ezért legfeljebb egy sor jöhet;
  /// a `getSingleOrNull` ezt az invariánst ki is kényszeríti — ha valaha
  /// mégis több sor lenne, itt derül ki, nem csendben.
  Future<TrackStats?> read(String raceId) async {
    final query = _database.select(_database.raceTrackStats)
      ..where((row) => row.raceId.equals(raceId));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return TrackStats(
      maxSpeedMps: row.maxSpeedMps,
      avgSpeedMps: row.avgSpeedMps,
      distanceMeters: row.distanceMeters,
    );
  }

  /// A kiszámolt statisztika kiírása; azonos `raceId`-ra felülír.
  ///
  /// `insertOnConflictUpdate`: a `raceId` elsődleges kulcs, tehát az
  /// ütközés-feloldás egyetlen körben elvégzi a beszúrást és a frissítést
  /// is. Külön olvasás-majd-döntés nem kell, és nem is lenne helyes: két
  /// utasítás közé beférne egy másik feltöltés.
  Future<void> write(
    String raceId,
    TrackStats stats, {
    required int sampleCount,
    required DateTime computedAt,
  }) async {
    await _database
        .into(_database.raceTrackStats)
        .insertOnConflictUpdate(
          RaceTrackStatsCompanion.insert(
            raceId: raceId,
            distanceMeters: Value(stats.distanceMeters),
            maxSpeedMps: Value(stats.maxSpeedMps),
            avgSpeedMps: Value(stats.avgSpeedMps),
            sampleCount: sampleCount,
            computedAt: computedAt,
          ),
        );
  }
}
