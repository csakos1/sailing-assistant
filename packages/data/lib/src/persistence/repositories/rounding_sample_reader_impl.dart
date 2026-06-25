import 'dart:convert';

import 'package:data/src/engine/race_snapshot.dart';
import 'package:data/src/persistence/app_database.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// A [RoundingSampleReader] Drift-alapú implementációja (ADR 0034 D4).
///
/// A `snapshot_logs` táblát olvassa: a `raceId`-re szűrt sorokat `timestamp`
/// szerint növekvő (időrendi) sorrendben, a tárolt `snapshotJson`-t a
/// `RaceSnapshot.fromJson`-nal dekódolja, majd a domain [RoundingSample]
/// read-modellre mappeli. A `RaceSnapshot` data-DTO nem szivárog ki: a
/// publikus [call] csak [RoundingSample]-öket ad vissza (ADR 0034 D3).
///
/// A séma változatlan (ADR 0034): a tábla az ADR 0022 író-oldalból már
/// létezik, csak olvassuk. Az olvasás a UI-izolátum elsődleges kapcsolatán
/// fut (post-race, on-demand a detail-képernyőről).
class RoundingSampleReaderImpl {
  /// A `database` a Drift adatbázis (az elsődleges UI-kapcsolat).
  RoundingSampleReaderImpl(this._database);

  final AppDatabase _database;

  /// A `raceId` versenyhez tartozó pillanatképek időrendben; üres lista, ha
  /// nincs rögzített `snapshot_logs` ehhez a versenyhez.
  Future<List<RoundingSample>> call(String raceId) async {
    final query = _database.select(_database.snapshotLogs)
      ..where((r) => r.raceId.equals(raceId))
      ..orderBy([(r) => OrderingTerm.asc(r.timestamp)]);
    final rows = await query.get();
    return [for (final row in rows) _toRoundingSample(row.snapshotJson)];
  }
}

// Egy tárolt snapshot-JSON → domain read-modell. A `RaceSnapshot.fromJson` a
// data-DTO-t építi vissza; ebből vesszük az elemzéshez kellő primitív mezőket
// (a value-objectek fok-/SI-getterein át, a tool egykori parseSnapshot-jával
// azonos szemantikával).
RoundingSample _toRoundingSample(String snapshotJson) {
  final snapshot = RaceSnapshot.fromJson(
    jsonDecode(snapshotJson) as Map<String, dynamic>,
  );
  final boat = snapshot.boatState;
  final prediction = snapshot.prediction;
  return RoundingSample(
    tickTime: snapshot.tickTime,
    raceStatus: snapshot.raceStatus.name,
    twdQuality: snapshot.twdQuality.name,
    markName: prediction?.mark.name,
    predictedTwaAtMarkDeg: prediction?.predictedTwaAtMark?.degrees,
    shiftConfidence: prediction?.shiftConfidence.name,
    forecastBandDeg: prediction?.forecastBandDegrees,
    bearingToMarkDeg: prediction?.bearingToMark.degrees,
    currentTwaDeg: snapshot.wind?.trueAngleWater?.degrees,
    sogMps: boat.speedOverGround?.metersPerSecond,
    cogDeg: boat.courseOverGround?.degrees,
  );
}
