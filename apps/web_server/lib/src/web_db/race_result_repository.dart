import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A `race_results` tábla olvasó-írója (ADR 0048 D3, D9 + Addendum 3 I2).
///
/// Csak fordít a Drift-sor és a szerződés típusai között. A validáció és a
/// normalizálás a hívó dolga (`ValidateRaceResultInput`), ide már érvényes
/// bemenet érkezik.
class RaceResultRepository {
  /// Repository a [_database] fölött.
  RaceResultRepository(this._database);

  final WebDatabase _database;

  /// A [raceId] verseny eredménye, vagy `null`, ha még nincs rögzítve.
  Future<RaceResult?> get(String raceId) async {
    final query = _database.select(_database.raceResults)
      ..where((row) => row.raceId.equals(raceId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toResult(row);
  }

  /// Az összes eredmény, a verseny azonosítója szerint.
  Future<Map<String, RaceResult>> getAll() async {
    final rows = await _database.select(_database.raceResults).get();
    return {for (final row in rows) row.raceId: _toResult(row)};
  }

  /// A [content] mentése a [raceId] versenyhez, felülírva a korábbit.
  ///
  /// A visszaadott érték a **visszaolvasott** sor: az `updatedAt`
  /// másodpercre csonkul, így a válasz pontosan az, amit egy későbbi `get`
  /// is adna.
  Future<RaceResult> upsert(
    String raceId,
    RaceResultInput content, {
    required DateTime updatedAt,
  }) async {
    final (classPlace, classStatus) = _placingColumns(content.classPlace);
    final (overallPlace, overallStatus) = _placingColumns(content.overallPlace);
    final (monohullPlace, monohullStatus) = _placingColumns(
      content.monohullPlace,
    );
    // insertOrReplace: az egyetlen kulcs a raceId, idegen kulcs és trigger
    // nincs, ezért a csere egyenértékű a frissítéssel, és a RETURNING egy
    // körben visszaadja a tárolt sort.
    final row = await _database
        .into(_database.raceResults)
        .insertReturning(
          RaceResultsCompanion.insert(
            raceId: raceId,
            classPlace: Value(classPlace),
            classStatus: Value(classStatus),
            classFleetSize: Value(content.classFleetSize),
            overallPlace: Value(overallPlace),
            overallStatus: Value(overallStatus),
            overallFleetSize: Value(content.overallFleetSize),
            monohullPlace: Value(monohullPlace),
            monohullStatus: Value(monohullStatus),
            monohullFleetSize: Value(content.monohullFleetSize),
            ysNumberHundredths: Value(content.ysNumberHundredths),
            officialStartMs: Value(
              content.officialStart?.millisecondsSinceEpoch,
            ),
            officialFinishMs: Value(
              content.officialFinish?.millisecondsSinceEpoch,
            ),
            prize: Value(content.prize),
            summary: Value(content.summary),
            updatedAt: updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
    return _toResult(row);
  }

  /// A [raceId] verseny eredményének törlése; nem hiba, ha nem volt.
  Future<void> delete(String raceId) async {
    await (_database.delete(
      _database.raceResults,
    )..where((row) => row.raceId.equals(raceId))).go();
  }

  // A Drift a unix időt helyi zónájú DateTime-ként adja vissza; a szerződés
  // UTC-t ír elő (ADR 0047 Addendum 1 A4).
  RaceResult _toResult(RaceResultRow row) => RaceResult(
    raceId: row.raceId,
    content: RaceResultInput(
      classPlace: _placingOf(row.classPlace, row.classStatus),
      classFleetSize: row.classFleetSize,
      overallPlace: _placingOf(row.overallPlace, row.overallStatus),
      overallFleetSize: row.overallFleetSize,
      monohullPlace: _placingOf(row.monohullPlace, row.monohullStatus),
      monohullFleetSize: row.monohullFleetSize,
      ysNumberHundredths: row.ysNumberHundredths,
      officialStart: _utcFromMillis(row.officialStartMs),
      officialFinish: _utcFromMillis(row.officialFinishMs),
      prize: row.prize,
      summary: row.summary,
    ),
    updatedAt: row.updatedAt.toUtc(),
  );
}

const String _dnfStatus = 'dnf';
const String _dsqStatus = 'dsq';

(int?, String?) _placingColumns(Placing? placing) => switch (placing) {
  null => (null, null),
  FinishPlace(:final place) => (place, null),
  Dnf() => (null, _dnfStatus),
  Dsq() => (null, _dsqStatus),
};

// A CHECK miatt a szám és a státusz közül legfeljebb az egyik van kitöltve;
// ismeretlen státusz a CHECK miatt nem kerülhet a táblába.
Placing? _placingOf(int? number, String? status) => switch ((number, status)) {
  (final int place, _) => FinishPlace(place),
  (null, _dnfStatus) => const Dnf(),
  (null, _dsqStatus) => const Dsq(),
  _ => null,
};

DateTime? _utcFromMillis(int? millis) => millis == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
