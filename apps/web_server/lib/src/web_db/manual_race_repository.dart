import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A `manual_races` tábla olvasó-írója (ADR 0048 D2, D9 + Addendum 3 I2).
///
/// A validáció a hívó dolga (`ValidateManualRaceInput`). Az eredményt nem
/// kezeli: azt a `RaceResultRepository` írja, ugyanabban a tranzakcióban.
class ManualRaceRepository {
  /// Repository a [_database] fölött.
  ManualRaceRepository(this._database);

  final WebDatabase _database;

  /// Az [id] kézi verseny, vagy `null`, ha nincs ilyen.
  Future<ManualRaceRecord?> get(String id) async {
    final query = _database.select(_database.manualRaces)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  /// Az összes kézi verseny.
  Future<List<ManualRaceRecord>> getAll() async {
    final rows = await _database.select(_database.manualRaces).get();
    return [for (final row in rows) _toRecord(row)];
  }

  /// Új kézi verseny az [id] azonosítóval; a visszaolvasott rekord.
  Future<ManualRaceRecord> insert(
    String id,
    ManualRaceInput input, {
    required DateTime now,
  }) async {
    final row = await _database
        .into(_database.manualRaces)
        .insertReturning(
          ManualRacesCompanion.insert(
            id: id,
            name: input.name,
            date: input.date.toIso(),
            distanceMeters: Value(input.distanceMeters),
            maxSpeedMps: Value(input.maxSpeedMps),
            avgWindMps: Value(input.avgWindMps),
            maxWindMps: Value(input.maxWindMps),
            windPoint: Value(input.windPoint?.index),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return _toRecord(row);
  }

  /// Az [id] kézi verseny alapadatainak cseréje; `null`, ha nincs ilyen.
  ///
  /// A `createdAt` megmarad, az `updatedAt` a [now] lesz.
  Future<ManualRaceRecord?> update(
    String id,
    ManualRaceInput input, {
    required DateTime now,
  }) async {
    final rows =
        await (_database.update(
          _database.manualRaces,
        )..where((row) => row.id.equals(id))).writeReturning(
          ManualRacesCompanion(
            name: Value(input.name),
            date: Value(input.date.toIso()),
            distanceMeters: Value(input.distanceMeters),
            maxSpeedMps: Value(input.maxSpeedMps),
            avgWindMps: Value(input.avgWindMps),
            maxWindMps: Value(input.maxWindMps),
            windPoint: Value(input.windPoint?.index),
            updatedAt: Value(now),
          ),
        );
    return rows.isEmpty ? null : _toRecord(rows.single);
  }

  /// Az [id] kézi verseny törlése; igaz, ha volt ilyen.
  Future<bool> delete(String id) async {
    final count = await (_database.delete(
      _database.manualRaces,
    )..where((row) => row.id.equals(id))).go();
    return count > 0;
  }

  ManualRaceRecord _toRecord(ManualRaceRow row) => ManualRaceRecord(
    id: row.id,
    input: ManualRaceInput(
      name: row.name,
      date: _dateOf(row),
      distanceMeters: row.distanceMeters,
      maxSpeedMps: row.maxSpeedMps,
      avgWindMps: row.avgWindMps,
      maxWindMps: row.maxWindMps,
      windPoint: switch (row.windPoint) {
        null => null,
        final int index => CompassPoint.values[index],
      },
    ),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );

  // A napot csak ez a repository írja, mindig `toIso()`-val; egy olvashatatlan
  // érték sérült fájlt jelent, nem rossz bemenetet, ezért kivétel.
  static CalendarDate _dateOf(ManualRaceRow row) =>
      CalendarDate.tryParse(row.date) ??
      (throw StateError('Sérült dátum a manual_races-ben (${row.id}).'));
}
