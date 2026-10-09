import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A polár-cache három táblájának olvasó-írója (ADR 0049 D10, Addendum 4
/// U4).
///
/// Egy verseny sora, hisztogramja és szélvödrei együtt íródnak és
/// törlődnek, egy tranzakcióban. A frissesség eldöntése nem az övé.
class PolarStatsRepository {
  /// Repository a [_database] fölött.
  PolarStatsRepository(this._database);

  final WebDatabase _database;

  /// A [raceId] verseny tárolt polár-teljesítménye, vagy `null`.
  Future<CachedPolarStats?> get(String raceId) async =>
      (await _read({raceId}))[raceId];

  /// Az összes tárolt polár-teljesítmény, a verseny azonosítója szerint.
  Future<Map<String, CachedPolarStats>> getAll() => _read(null);

  /// A [stats] mentése a [raceId] versenyhez, felülírva a korábbit.
  Future<void> put(String raceId, CachedPolarStats stats) {
    final (kind, window) = switch (stats.window) {
      OfficialWindow(:final window) => (_official, window),
      RecordingWindow(:final window) => (_recording, window),
      // Programozói hiba: a beírt értékeknek nincs polár-mintája.
      ManualEntry() => throw ArgumentError.value(
        stats.window,
        'stats.window',
        'beírt értéknek nincs polár-cache-e',
      ),
    };
    final performance = stats.performance;
    return _database.transaction(() async {
      await _deleteRows([raceId]);
      await _database
          .into(_database.racePolarStatsTable)
          .insert(
            RacePolarStatsTableCompanion.insert(
              raceId: raceId,
              windowKind: kind,
              windowStartMs: window.start.millisecondsSinceEpoch,
              windowEndMs: window.end.millisecondsSinceEpoch,
              referenceFingerprint: stats.fingerprint,
              measuredSeconds: performance.measuredSeconds,
              pctSecondsSum: performance.pctSecondsSum,
              twsMpsSecondsSum: performance.twsMpsSecondsSum,
              bestFivePct: Value(performance.bestFiveSecondsPct),
              computedAt: stats.computedAt,
            ),
          );
      await _database.batch((batch) {
        batch
          ..insertAll(_database.racePolarHistogramTable, [
            for (final MapEntry(key: bin, value: seconds)
                in performance.histogram.entries)
              RacePolarHistogramTableCompanion.insert(
                raceId: raceId,
                pctBin: bin,
                seconds: seconds,
              ),
          ])
          ..insertAll(_database.racePolarBucketsTable, [
            for (final MapEntry(key: index, value: bucket)
                in performance.buckets.entries)
              RacePolarBucketsTableCompanion.insert(
                raceId: raceId,
                twsBucket: index,
                seconds: bucket.seconds,
                pctSecondsSum: bucket.pctSecondsSum,
              ),
          ]);
      });
    });
  }

  /// A [raceIds] versenyek tárolt sorainak törlése; nem hiba, ha nem
  /// voltak.
  Future<void> deleteAll(Iterable<String> raceIds) {
    final ids = raceIds.toList();
    if (ids.isEmpty) return Future<void>.value();
    return _database.transaction(() => _deleteRows(ids));
  }

  Future<void> _deleteRows(List<String> raceIds) async {
    await (_database.delete(
      _database.racePolarHistogramTable,
    )..where((row) => row.raceId.isIn(raceIds))).go();
    await (_database.delete(
      _database.racePolarBucketsTable,
    )..where((row) => row.raceId.isIn(raceIds))).go();
    await (_database.delete(
      _database.racePolarStatsTable,
    )..where((row) => row.raceId.isIn(raceIds))).go();
  }

  // A [raceIds] versenyek sorai; `null` esetén mindegyik.
  Future<Map<String, CachedPolarStats>> _read(Set<String>? raceIds) async {
    final statsQuery = _database.select(_database.racePolarStatsTable);
    final histogramQuery = _database.select(_database.racePolarHistogramTable);
    final bucketsQuery = _database.select(_database.racePolarBucketsTable);
    if (raceIds != null) {
      statsQuery.where((row) => row.raceId.isIn(raceIds));
      histogramQuery.where((row) => row.raceId.isIn(raceIds));
      bucketsQuery.where((row) => row.raceId.isIn(raceIds));
    }
    final histograms = <String, Map<int, int>>{};
    for (final row in await histogramQuery.get()) {
      histograms.putIfAbsent(row.raceId, () => {})[row.pctBin] = row.seconds;
    }
    final buckets = <String, Map<int, PolarBucket>>{};
    for (final row in await bucketsQuery.get()) {
      buckets.putIfAbsent(row.raceId, () => {})[row.twsBucket] = PolarBucket(
        seconds: row.seconds,
        pctSecondsSum: row.pctSecondsSum,
      );
    }
    return {
      for (final row in await statsQuery.get())
        row.raceId: _toStats(
          row,
          histograms[row.raceId] ?? const {},
          buckets[row.raceId] ?? const {},
        ),
    };
  }

  CachedPolarStats _toStats(
    RacePolarStatsRow row,
    Map<int, int> histogram,
    Map<int, PolarBucket> buckets,
  ) {
    final window = TimeWindow(
      start: _utcFromMillis(row.windowStartMs),
      end: _utcFromMillis(row.windowEndMs),
    );
    return CachedPolarStats(
      // A CHECK miatt más érték nem kerülhet a táblába.
      window: row.windowKind == _official
          ? OfficialWindow(window)
          : RecordingWindow(window),
      fingerprint: row.referenceFingerprint,
      performance: PolarPerformance(
        measuredSeconds: row.measuredSeconds,
        pctSecondsSum: row.pctSecondsSum,
        twsMpsSecondsSum: row.twsMpsSecondsSum,
        histogram: histogram,
        buckets: buckets,
        bestFiveSecondsPct: row.bestFivePct,
      ),
      computedAt: row.computedAt,
    );
  }
}

const String _official = 'official';
const String _recording = 'recording';

DateTime _utcFromMillis(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
