import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/annotation/web_database.dart';

/// A `race_annotations` tábla olvasó-írója (ADR 0047 Addendum 3 C8).
///
/// Csak fordít a Drift-sor és a szerződés típusai között. A validáció és
/// a normalizálás a hívó dolga (`ValidateRaceAnnotationInput`), ide már
/// érvényes bemenet érkezik.
class AnnotationRepository {
  /// Repository a [_database] fölött.
  AnnotationRepository(this._database);

  final WebDatabase _database;

  /// A [raceId] verseny annotációja, vagy `null`, ha még nincs rögzítve.
  Future<RaceAnnotation?> get(String raceId) async {
    final query = _database.select(_database.raceAnnotations)
      ..where((row) => row.raceId.equals(raceId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toAnnotation(row);
  }

  /// Az összes annotáció, race UUID szerint.
  Future<Map<String, RaceAnnotation>> getAll() async {
    final rows = await _database.select(_database.raceAnnotations).get();
    return {for (final row in rows) row.raceId: _toAnnotation(row)};
  }

  /// A [content] mentése a [raceId] versenyhez, felülírva a korábbit.
  ///
  /// A visszaadott érték a **visszaolvasott** sor: a Drift az időt unix
  /// másodpercként tárolja, így a válasz pontosan az, amit egy későbbi
  /// `get` is adna (Addendum 3 C3).
  Future<RaceAnnotation> upsert(
    String raceId,
    RaceAnnotationInput content, {
    required DateTime updatedAt,
  }) async {
    // insertOrReplace: a tábla egyetlen kulcsa a raceId, idegen kulcs és
    // trigger nincs, ezért a törlés-és-beszúrás itt egyenértékű a
    // frissítéssel, és a RETURNING egy körben visszaadja a tárolt sort.
    final row = await _database
        .into(_database.raceAnnotations)
        .insertReturning(
          RaceAnnotationsCompanion.insert(
            raceId: raceId,
            overallPlace: Value(content.overallPlace),
            overallFleetSize: Value(content.overallFleetSize),
            classPlace: Value(content.classPlace),
            classFleetSize: Value(content.classFleetSize),
            summary: Value(content.summary),
            updatedAt: updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
    return _toAnnotation(row);
  }

  /// A [raceId] verseny annotációjának törlése; nem hiba, ha nem volt.
  Future<void> delete(String raceId) async {
    await (_database.delete(
      _database.raceAnnotations,
    )..where((row) => row.raceId.equals(raceId))).go();
  }

  // A Drift a unix időt helyi időzónájú DateTime-ként adja vissza; a
  // szerződés UTC-t ír elő (Addendum 1 A4).
  RaceAnnotation _toAnnotation(RaceAnnotationRow row) => RaceAnnotation(
    raceId: row.raceId,
    content: RaceAnnotationInput(
      overallPlace: row.overallPlace,
      overallFleetSize: row.overallFleetSize,
      classPlace: row.classPlace,
      classFleetSize: row.classFleetSize,
      summary: row.summary,
    ),
    updatedAt: row.updatedAt.toUtc(),
  );
}
