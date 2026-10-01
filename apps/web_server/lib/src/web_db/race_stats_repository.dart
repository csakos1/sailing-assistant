import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A `race_stats` cache olvasó-írója (ADR 0048 D4, D9 + Addendum 3 I2).
///
/// Az érvényesség eldöntése nem az övé: a hívó veti össze a tárolt ablakot
/// a várt ablakkal (I4).
class RaceStatsRepository {
  /// Repository a [_database] fölött.
  RaceStatsRepository(this._database);

  final WebDatabase _database;

  /// A [raceId] verseny tárolt statisztikája, vagy `null`.
  Future<CachedRaceStats?> get(String raceId) async {
    final query = _database.select(_database.raceStatsTable)
      ..where((row) => row.raceId.equals(raceId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toStats(row);
  }

  /// Az összes tárolt statisztika, a verseny azonosítója szerint.
  Future<Map<String, CachedRaceStats>> getAll() async {
    final rows = await _database.select(_database.raceStatsTable).get();
    return {for (final row in rows) row.raceId: _toStats(row)};
  }

  /// A [stats] mentése a [raceId] versenyhez, felülírva a korábbit.
  Future<void> put(String raceId, CachedRaceStats stats) async {
    final (kind, window) = switch (stats.window) {
      OfficialWindow(:final window) => (_official, window),
      RecordingWindow(:final window) => (_recording, window),
      // Programozói hiba: a kézi verseny statjai beírt értékek (I2).
      ManualEntry() => throw ArgumentError.value(
        stats.window,
        'stats.window',
        'kézi versenynek nincs statisztika-cache-e',
      ),
    };
    await _database
        .into(_database.raceStatsTable)
        .insert(
          RaceStatsTableCompanion.insert(
            raceId: raceId,
            windowKind: kind,
            windowStartMs: window.start.millisecondsSinceEpoch,
            windowEndMs: window.end.millisecondsSinceEpoch,
            distanceMeters: Value(stats.track.distanceMeters),
            avgSpeedMps: Value(stats.track.avgSpeedMps),
            maxSpeedMps: Value(stats.track.maxSpeedMps),
            avgWindMps: Value(stats.wind.avgWindMps),
            maxWindMps: Value(stats.wind.maxWindMps),
            windDirDeg: Value(stats.wind.directionDeg),
            computedAt: stats.computedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  CachedRaceStats _toStats(RaceStatsRow row) {
    final window = TimeWindow(
      start: _utcFromMillis(row.windowStartMs),
      end: _utcFromMillis(row.windowEndMs),
    );
    return CachedRaceStats(
      // A CHECK miatt más érték nem kerülhet a táblába.
      window: row.windowKind == _official
          ? OfficialWindow(window)
          : RecordingWindow(window),
      track: TrackStats(
        distanceMeters: row.distanceMeters,
        avgSpeedMps: row.avgSpeedMps,
        maxSpeedMps: row.maxSpeedMps,
      ),
      wind: WindStats(
        avgWindMps: row.avgWindMps,
        maxWindMps: row.maxWindMps,
        directionDeg: row.windDirDeg,
      ),
      computedAt: row.computedAt.toUtc(),
    );
  }
}

const String _official = 'official';
const String _recording = 'recording';

DateTime _utcFromMillis(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
