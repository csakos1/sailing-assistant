import 'package:domain/domain.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/transaction_runner.dart';

/// Egy telemetriás verseny végleges törlése a szerverről (ADR 0057).
///
/// Csak az archívum befejezett versenyét törli; a kézi verseny a saját
/// szolgáltatásán át törlődik (ADR 0048 D6). Az archívum az igazság
/// forrása, ezért elöl jár, utána a webes sorok egy tranzakcióban (D6).
/// Tombstone nincs: egy új feltöltés a versenyt visszahozza (D2).
class TelemetryRaceDeletionService {
  /// Szolgáltatás az archívum [races] tárával és a webes tárakkal; a
  /// [lock] az import és a mentések közös írási zárja.
  TelemetryRaceDeletionService({
    required RaceRepository races,
    required RaceResultRepository results,
    required RaceStatsRepository stats,
    required PolarStatsRepository polar,
    required TransactionRunner runInWebTransaction,
    required SerialLock lock,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _results = results,
       _stats = stats,
       _polar = polar,
       _runInWebTransaction = runInWebTransaction,
       _lock = lock,
       _log = log;

  final RaceRepository _races;
  final RaceResultRepository _results;
  final RaceStatsRepository _stats;
  final PolarStatsRepository _polar;
  final TransactionRunner _runInWebTransaction;
  final SerialLock _lock;
  final ServerLog _log;

  /// A [raceId] verseny törlése az összes adatával; igaz, ha az archívum
  /// befejezett versenye volt.
  Future<bool> delete(String raceId) => _lock.run(() async {
    final race = await _races.getRace(raceId);
    if (race == null || race.status != RaceStatus.finished) return false;
    // A CASCADE a bójákat, a telemetriát, a snapshot-logot és a
    // race_track_stats sort is viszi.
    await _races.delete(raceId);
    await _deleteWebRows(raceId);
    return true;
  });

  // A verseny ekkor már nincs az archívumban, ezért a webes sorai sehol
  // nem látszanak: egy hiba itt csak naplósor (ADR 0057 D6).
  Future<void> _deleteWebRows(String raceId) async {
    try {
      await _runInWebTransaction(() async {
        await _results.delete(raceId);
        await _stats.delete(raceId);
        await _polar.deleteAll([raceId]);
      });
    } on Object catch (error) {
      _log('a törölt verseny webes sorai megmaradtak ($raceId): $error');
    }
  }
}
