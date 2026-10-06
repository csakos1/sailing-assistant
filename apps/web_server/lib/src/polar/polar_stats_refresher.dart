import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_stats_calculator.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';

/// A polár-cache frissítése (ADR 0049 D10, Addendum 4 U6).
///
/// A hívók a közös `SerialLock` alatt hívják (ADR 0048 Addendum 3 I5),
/// ezért itt nincs saját zár. Egy verseny számítási hibája nem állítja
/// meg a többit: a hibát naplózza, és a sor elavult marad.
class PolarStatsRefresher {
  /// Frissítő a [catalog] versenyeire.
  PolarStatsRefresher({
    required PolarRaceCatalog catalog,
    required PolarStatsRepository repository,
    required PolarStatsCalculator calculate,
    ServerLog log = ignoreServerLog,
  }) : _catalog = catalog,
       _repository = repository,
       _calculate = calculate,
       _log = log;

  final PolarRaceCatalog _catalog;
  final PolarStatsRepository _repository;
  final PolarStatsCalculator _calculate;
  final ServerLog _log;

  /// Import után: az új és frissített telemetriás versenyek mindig, a
  /// többi telemetriás csak nem friss sornál.
  ///
  /// Az `ImportFollowUp` kontraktushoz illeszkedik; hibát nem enged ki,
  /// mert a merge ekkor már lezárult.
  Future<void> afterImport(ImportReport report) async {
    try {
      final changed = {
        for (final race in report.added) race.id,
        for (final race in report.updated) race.id,
      };
      final cached = await _repository.getAll();
      for (final race in await _catalog.all()) {
        if (race.source != PolarSampleSource.telemetry) continue;
        if (!changed.contains(race.id) && _isFresh(race, cached[race.id])) {
          continue;
        }
        await _refresh(race);
      }
    } on Object catch (error) {
      _log('polár-frissítés az import után sikertelen: $error');
    }
  }

  /// Mentés után: a [raceId] verseny, ha a sora nem friss. Polár-forrás
  /// nélküli versenyre nem tesz semmit.
  Future<void> refreshIfStale(String raceId) async {
    try {
      final race = await _catalog.byId(raceId);
      if (race == null) return;
      if (_isFresh(race, await _repository.get(raceId))) return;
      await _refresh(race);
    } on Object catch (error) {
      _log('polár-frissítés sikertelen ($raceId): $error');
    }
  }

  /// Induláskor: minden nem friss verseny újraszámolása, és a már nem
  /// létező versenyek sorainak törlése.
  Future<void> refreshAllStale() async {
    try {
      final races = await _catalog.all();
      final cached = await _repository.getAll();
      final known = {for (final race in races) race.id};
      await _repository.deleteAll([
        for (final raceId in cached.keys)
          if (!known.contains(raceId)) raceId,
      ]);
      var refreshed = 0;
      for (final race in races) {
        if (_isFresh(race, cached[race.id])) continue;
        await _refresh(race);
        refreshed++;
      }
      _log('polár-cache: $refreshed verseny frissítve');
    } on Object catch (error) {
      _log('polár-frissítés induláskor sikertelen: $error');
    }
  }

  bool _isFresh(PolarRace race, CachedPolarStats? cached) =>
      polarCacheStateOf(
        cached,
        race.expectedWindow,
        _calculate.fingerprint,
      ) ==
      PolarCacheState.fresh;

  Future<void> _refresh(PolarRace race) async {
    try {
      await _repository.put(race.id, await _calculate(race));
    } on Object catch (error) {
      _log('polár-számítás sikertelen (${race.id}): $error');
    }
  }
}
