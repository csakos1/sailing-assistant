import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A `legacy_track_samples` tábla olvasó-írója (ADR 0050 D3).
///
/// A [readWindow] a `WindowedTrackSampleReader` és a `WindSampleReader`
/// kontraktust is kiszolgálja: a minta mindkét domain-szerződést
/// megvalósítja, így a meglévő `RaceStatsCalculator` változatlanul
/// számol a régi trackből is.
///
/// A tranzakció a hívó dolga: a csere (törlés + beszúrás) és a kézi
/// verseny törlése a hívó tranzakciójában fut.
class LegacyTrackRepository {
  /// Repository a [_database] fölött.
  LegacyTrackRepository(this._database);

  final WebDatabase _database;

  /// A [raceId] verseny mintái időrendben; a [window] `null` értéke a
  /// teljes tracket jelenti, különben csak az ablakba esők jönnek (a
  /// határokat is beleértve).
  ///
  /// Az időrend a tüske-szűrt max. szélhez kell (ADR 0048 Addendum 5 L3).
  Future<List<LegacyTrackSample>> readWindow(
    String raceId,
    TimeWindow? window,
  ) async {
    final query = _database.select(_database.legacyTrackSamples)
      ..where((row) => _matches(row, raceId, window))
      ..orderBy([(row) => OrderingTerm.asc(row.timestampMs)]);
    final rows = await query.get();
    return [for (final row in rows) _toSample(row)];
  }

  /// A [raceId] verseny trackjének cseréje a [samples]-re; üres lista a
  /// track törlése.
  Future<void> replace(String raceId, List<LegacyTrackSample> samples) async {
    await delete(raceId);
    if (samples.isEmpty) return;
    await _database.batch(
      (batch) => batch.insertAll(_database.legacyTrackSamples, [
        for (final sample in samples) _toCompanion(raceId, sample),
      ]),
    );
  }

  /// A [raceId] verseny trackjének törlése; nem hiba, ha nem volt.
  Future<void> delete(String raceId) async {
    await (_database.delete(
      _database.legacyTrackSamples,
    )..where((row) => row.raceId.equals(raceId))).go();
  }

  /// Igaz, ha a [raceId] versenynek van legalább egy mintája.
  Future<bool> hasTrack(String raceId) async {
    final row = await _database
        .customSelect(
          'SELECT 1 AS found FROM legacy_track_samples '
          'WHERE race_id = ? LIMIT 1',
          variables: [Variable.withString(raceId)],
          readsFrom: {_database.legacyTrackSamples},
        )
        .getSingleOrNull();
    return row != null;
  }

  /// A trackes versenyek azonosítói.
  Future<Set<String>> raceIdsWithTrack() async {
    final rows = await _database
        .customSelect(
          'SELECT DISTINCT race_id FROM legacy_track_samples',
          readsFrom: {_database.legacyTrackSamples},
        )
        .get();
    return {for (final row in rows) row.read<String>('race_id')};
  }

  Expression<bool> _matches(
    $LegacyTrackSamplesTable row,
    String raceId,
    TimeWindow? window,
  ) {
    final ofRace = row.raceId.equals(raceId);
    if (window == null) return ofRace;
    return ofRace &
        row.timestampMs.isBetweenValues(
          window.start.millisecondsSinceEpoch,
          window.end.millisecondsSinceEpoch,
        );
  }

  LegacyTrackSamplesCompanion _toCompanion(
    String raceId,
    LegacyTrackSample sample,
  ) => LegacyTrackSamplesCompanion.insert(
    raceId: raceId,
    timestampMs: sample.timestamp.millisecondsSinceEpoch,
    latDeg: Value(sample.latDeg),
    lonDeg: Value(sample.lonDeg),
    sogMps: Value(sample.sogMps),
    stwMps: Value(sample.stwMps),
    twsMps: Value(sample.twsMps),
    twdDeg: Value(sample.twdDeg),
    polarTwsMps: Value(sample.polarTwsMps),
    polarTwaDeg: Value(sample.polarTwaDeg),
  );

  LegacyTrackSample _toSample(LegacyTrackSampleRow row) => LegacyTrackSample(
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      row.timestampMs,
      isUtc: true,
    ),
    latDeg: row.latDeg,
    lonDeg: row.lonDeg,
    sogMps: row.sogMps,
    stwMps: row.stwMps,
    twsMps: row.twsMps,
    twdDeg: row.twdDeg,
    polarTwsMps: row.polarTwsMps,
    polarTwaDeg: row.polarTwaDeg,
  );
}
