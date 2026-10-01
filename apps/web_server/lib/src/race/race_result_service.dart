import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/serial_lock.dart';
import 'package:web_server/src/stats/race_stats_refresher.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

/// Egy telemetriás verseny eredményének mentése (ADR 0048 D3, D6 +
/// Addendum 3 I4, I7).
///
/// A kézi verseny eredménye a kézi verseny végpontjain át íródik, ezért
/// itt csak az archívum befejezett versenye számít létezőnek. Mentés után
/// a statisztika a közös zár alatt frissül, ha a hivatalos idők az ablakot
/// megváltoztatták.
class RaceResultService {
  /// Szolgáltatás az archívum [races] olvasójával.
  RaceResultService({
    required RaceRepository races,
    required RaceResultRepository results,
    required RaceStatsRefresher refresher,
    required SerialLock lock,
    DateTime Function() now = DateTime.now,
  }) : _races = races,
       _results = results,
       _refresher = refresher,
       _lock = lock,
       _now = now;

  final RaceRepository _races;
  final RaceResultRepository _results;
  final RaceStatsRefresher _refresher;
  final SerialLock _lock;
  final DateTime Function() _now;

  /// Igaz, ha a [raceId] az archívum befejezett versenye.
  Future<bool> isTelemetryRace(String raceId) async =>
      await _finishedRace(raceId) != null;

  /// A validált, normalizált [content] mentése; `null`, ha a verseny nincs
  /// az archívumban.
  ///
  /// Csupa üres tartalom törli az eredményt. A válasz ekkor is
  /// `RaceResult`, üres tartalommal és a törlés idejével (I7).
  Future<RaceResult?> save(String raceId, RaceResultInput content) async {
    if (await _finishedRace(raceId) == null) return null;

    final now = _now().toUtc();
    final RaceResult saved;
    if (content.isEmpty) {
      await _results.delete(raceId);
      saved = RaceResult(raceId: raceId, content: content, updatedAt: now);
    } else {
      saved = await _results.upsert(raceId, content, updatedAt: now);
    }
    await _lock.run(() => _refresher.refreshIfStale(raceId));
    return saved;
  }

  Future<Race?> _finishedRace(String raceId) async {
    final race = await _races.getRace(raceId);
    return race != null && race.status == RaceStatus.finished ? race : null;
  }
}
