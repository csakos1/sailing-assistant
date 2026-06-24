import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// A [MarkLibraryRepository] Drift-alapú implementációja (ADR 0032).
///
/// Persistence-only: a [SavedMark] már kész a hívótól (a verseny-mentés
/// hook-ja építi a `savedAt` órájával), a repo csak ment/olvas. A
/// koordináta egész E7-ben (`fok × 1e7`) tárolódik a pontos dedup-kulcs
/// miatt (ADR 0032 L4); a domain előjeles tizedes-fokot lát.
class MarkLibraryRepositoryImpl implements MarkLibraryRepository {
  /// A `database` a megosztott Drift adatbázis (a `savedMarks` táblával).
  MarkLibraryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveAll(Iterable<SavedMark> marks) {
    // Batch INSERT OR IGNORE: az azonosság-négyesre (name, latE7, lonE7,
    // sourceRaceName) húzott unique index ütközésekor a sor kimarad
    // (DoNothing, ADR 0032 L3) — a meglévő savedAt stabil marad.
    return _database.batch((batch) {
      batch.insertAll(
        _database.savedMarks,
        [
          for (final mark in marks)
            SavedMarksCompanion.insert(
              name: mark.name,
              latitudeE7: _toE7(mark.position.latitude),
              longitudeE7: _toE7(mark.position.longitude),
              sourceRaceName: mark.sourceRaceName,
              savedAt: mark.savedAt,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  @override
  Stream<List<SavedMark>> watchAll() {
    // A picker a legutóbb mentett bóját látja elöl (savedAt csökkenő).
    return (_database.select(_database.savedMarks)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .watch()
        .map((rows) => [for (final row in rows) _toSavedMark(row)]);
  }

  /// Egy DB-sor → domain [SavedMark]; az E7-koordináta vissza tizedes-fokra.
  SavedMark _toSavedMark(SavedMarkRow row) {
    return SavedMark(
      name: row.name,
      position: Coordinate(
        latitude: _fromE7(row.latitudeE7),
        longitude: _fromE7(row.longitudeE7),
      ),
      sourceRaceName: row.sourceRaceName,
      savedAt: row.savedAt,
    );
  }

  /// Előjeles tizedes-fok → egész E7 (`fok × 1e7`), pontos dedup-kulcs.
  int _toE7(double degrees) => (degrees * 1e7).round();

  /// Egész E7 → előjeles tizedes-fok.
  double _fromE7(int e7) => e7 / 1e7;
}
