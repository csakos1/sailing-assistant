import 'dart:developer' as developer;

import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:shared/shared.dart';

/// A [RaceRepository] Drift-alapú implementációja (ADR 0008 D7).
///
/// Persistence-only: az állapotátmeneteket a [Race] entitás factory-i
/// (`start`/`roundCurrentMark`/`finish`) végzik, a repo csak ment/olvas.
/// A race és a bóyái egy tranzakcióban íródnak, hogy ne maradjon
/// részlegesen mentett állapot egy megszakadt íráskor.
class RaceRepositoryImpl implements RaceRepository {
  /// A `database` a Drift adatbázis; a `now` az injektált óra a `createdAt`
  /// audit-időbélyeghez: a domain [Race] nem hordozza, ezért a data réteg
  /// adja — így a provider-réteg (D8) és a tesztek determinisztikusan
  /// felülírhatják.
  RaceRepositoryImpl(this._database, {DateTime Function() now = DateTime.now})
    : _now = now;

  final AppDatabase _database;
  final DateTime Function() _now;

  @override
  Future<void> save(Race race) {
    return _database.transaction(() async {
      // Race-sor upsert: insert-en a createdAt az injektált órából jön,
      // konfliktusnál (újra-mentés) a createdAt KIMARAD a DoUpdate-ből,
      // így az eredeti létrehozási idő stabil marad.
      await _database
          .into(_database.races)
          .insert(
            RacesCompanion.insert(
              id: race.id,
              name: race.name,
              statusIndex: race.status,
              startedAt: Value(race.startedAt),
              finishedAt: Value(race.finishedAt),
              activeMarkIndex: Value(race.activeMarkIndex),
              createdAt: _now(),
              scheduledStartAt: Value(race.scheduledStartAt),
              startPointName: Value(race.startPoint?.name),
              startPointLatitude: Value(race.startPoint?.position.latitude),
              startPointLongitude: Value(race.startPoint?.position.longitude),
            ),
            onConflict: DoUpdate(
              (_) => RacesCompanion(
                name: Value(race.name),
                statusIndex: Value(race.status),
                startedAt: Value(race.startedAt),
                finishedAt: Value(race.finishedAt),
                activeMarkIndex: Value(race.activeMarkIndex),
                scheduledStartAt: Value(race.scheduledStartAt),
                startPointName: Value(race.startPoint?.name),
                startPointLatitude: Value(race.startPoint?.position.latitude),
                startPointLongitude: Value(race.startPoint?.position.longitude),
              ),
            ),
          );

      // Bóyák delete-and-rewrite: a régi sorokat töröljük, majd a friss
      // listát batch-ben beszúrjuk. Ez helyesen kezeli a bóyaszám
      // csökkenését is (egy edit kevesebb bóyát menthet).
      await (_database.delete(
        _database.marks,
      )..where((m) => m.raceId.equals(race.id))).go();
      await _database.batch((batch) {
        batch.insertAll(_database.marks, [
          for (final mark in race.marks)
            MarksCompanion.insert(
              raceId: race.id,
              sequence: mark.sequence,
              name: mark.name,
              latitude: mark.position.latitude,
              longitude: mark.position.longitude,
              roundedAt: Value(mark.roundedAt),
            ),
        ]);
      });
    });
  }

  @override
  Future<Race?> getRace(String id) async {
    final raceRow = await (_database.select(
      _database.races,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (raceRow == null) {
      return null;
    }
    return _toRace(raceRow, await _marksForRace(id));
  }

  @override
  Stream<List<Race>> watchRaces() {
    return _database.select(_database.races).watch().asyncMap((raceRows) async {
      return [
        for (final raceRow in raceRows)
          _toRace(raceRow, await _marksForRace(raceRow.id)),
      ];
    });
  }

  @override
  Future<void> delete(String id) {
    // A bóyák és a telemetria FK-cascade-del törlődnek (PRAGMA foreign_keys
    // = ON a beforeOpen-ben, ADR 0008 D2).
    return (_database.delete(
      _database.races,
    )..where((r) => r.id.equals(id))).go();
  }

  /// Egy race bóyái `sequence` szerint növekvő sorrendben — ez a
  /// [Race.marks] pálya-sorrendje, függetlenül a beszúrási sorrendtől.
  Future<List<MarkRow>> _marksForRace(String raceId) {
    return (_database.select(_database.marks)
          ..where((m) => m.raceId.equals(raceId))
          ..orderBy([(m) => OrderingTerm.asc(m.sequence)]))
        .get();
  }

  /// DB-sorok → domain [Race]. A `createdAt` szándékosan elveszik: a domain
  /// entitásnak nincs ilyen mezője (write-only audit-oszlop).
  Race _toRace(RaceRow raceRow, List<MarkRow> markRows) {
    return Race(
      id: raceRow.id,
      name: raceRow.name,
      marks: [for (final markRow in markRows) _toMark(markRow)],
      status: raceRow.statusIndex,
      activeMarkIndex: raceRow.activeMarkIndex,
      startedAt: raceRow.startedAt,
      finishedAt: raceRow.finishedAt,
      scheduledStartAt: raceRow.scheduledStartAt,
      startPoint: _toStartPoint(raceRow),
    );
  }

  /// A rajthely három oszlopa → [StartPoint], vagy `null`.
  ///
  /// Ha mind a három üres, nincs rajthely. Egy hiányos vagy érvénytelen sor
  /// (pl. név koordináta nélkül, üres név, tartományon kívüli koordináta)
  /// defenzíven `null` rajthelyet ad egy figyelmeztetéssel (ADR 0055 D3):
  /// egy sérült sor miatt ne essen szét a versenylista, rajt előtt pedig az
  /// első bója marad a cél.
  StartPoint? _toStartPoint(RaceRow raceRow) {
    final name = raceRow.startPointName;
    final latitude = raceRow.startPointLatitude;
    final longitude = raceRow.startPointLongitude;
    if (name == null && latitude == null && longitude == null) return null;
    if (name == null || name.isEmpty || latitude == null || longitude == null) {
      _warnInvalidStartPoint(raceRow.id, 'incomplete row');
      return null;
    }
    final position = Coordinate.tryFromDegrees(
      latitude: latitude,
      longitude: longitude,
    );
    switch (position) {
      case Ok(value: final coordinate):
        return StartPoint(name: name, position: coordinate);
      case Err(error: final error):
        _warnInvalidStartPoint(raceRow.id, '$error');
        return null;
    }
  }

  /// Naplóz egy eldobott, érvénytelen rajthelyet (warning szint).
  static void _warnInvalidStartPoint(String raceId, String reason) {
    developer.log(
      'Invalid start point dropped for race $raceId: $reason',
      name: 'RaceRepository',
      level: 900,
    );
  }

  /// Egy [MarkRow] → domain [Mark]. A lat/lon mentéskor már validált
  /// [Coordinate]-ból jött, ezért a sima const ctor elég (nem a checked).
  Mark _toMark(MarkRow markRow) {
    return Mark(
      sequence: markRow.sequence,
      name: markRow.name,
      position: Coordinate(
        latitude: markRow.latitude,
        longitude: markRow.longitude,
      ),
      roundedAt: markRow.roundedAt,
    );
  }
}
