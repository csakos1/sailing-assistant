import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

/// A `race_stats` cache frissítése (ADR 0048 D4 + Addendum 3 I4).
///
/// Két alkalommal fut: import után és eredmény-mentés után. Mindkét hívó a
/// közös `SerialLock` alatt hívja (I5), ezért itt nincs saját zár.
///
/// Egy verseny számítási hibája nem állítja meg a többit: a hibát
/// naplózza, a `GET` addig memóriában számol, a következő import
/// újrapróbálja.
class RaceStatsRefresher {
  /// Frissítő az archívum [races] olvasójával és a webes tárakkal.
  RaceStatsRefresher({
    required RaceRepository races,
    required RaceResultRepository results,
    required RaceStatsRepository stats,
    required RaceStatsCalculator calculate,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _results = results,
       _stats = stats,
       _calculate = calculate,
       _log = log;

  final RaceRepository _races;
  final RaceResultRepository _results;
  final RaceStatsRepository _stats;
  final RaceStatsCalculator _calculate;
  final ServerLog _log;

  /// Import után: az új és frissített versenyek mindig, a többi befejezett
  /// verseny csak hiányzó vagy elavult sornál számolódik újra.
  ///
  /// Az `ImportFollowUp` kontraktus implementációja; a tear-offja adható át
  /// az importernek.
  ///
  /// Hibát nem enged ki: a merge ekkor már lezárult, egy követő lépés
  /// kudarca nem fordíthatja hibává az importot (`ImportFollowUp`).
  Future<void> afterImport(ImportReport report) async {
    try {
      await _refreshAfterImport(report);
    } on Object catch (error) {
      _log('statisztika-frissítés az import után sikertelen: $error');
    }
  }

  /// Eredmény-mentés után: a [raceId] verseny statisztikája, ha a várt ablak
  /// eltér a tárolttól.
  ///
  /// A versenyt és az eredményt maga olvassa vissza, a zár alatt: így egy
  /// közben lefutott import vagy egy újabb mentés állapota számít, nem a
  /// hívóé.
  Future<void> refreshIfStale(String raceId) async {
    final race = await _races.getRace(raceId);
    if (race == null || race.status != RaceStatus.finished) return;
    final result = await _results.get(raceId);
    final expected = _expectedWindowOf(race, result?.content);
    if (expected == null) return;
    final cached = await _stats.get(raceId);
    if (cached?.window == expected) return;
    await _refresh(raceId, expected);
  }

  Future<void> _refreshAfterImport(ImportReport report) async {
    final changed = {
      for (final race in report.added) race.id,
      for (final race in report.updated) race.id,
    };
    final results = await _results.getAll();
    final cached = await _stats.getAll();
    for (final race in await _finishedRaces()) {
      final expected = _expectedWindowOf(race, results[race.id]?.content);
      if (expected == null) continue;
      final isFresh = cached[race.id]?.window == expected;
      if (isFresh && !changed.contains(race.id)) continue;
      await _refresh(race.id, expected);
    }
  }

  StatsWindow? _expectedWindowOf(Race race, RaceResultInput? result) {
    final recording = recordingWindowOf(race);
    if (recording == null) {
      _log('a verseny rögzítési ablaka hiányos (${race.id}): kihagyva');
      return null;
    }
    return expectedStatsWindow(recording: recording, result: result);
  }

  Future<void> _refresh(String raceId, StatsWindow window) async {
    try {
      await _stats.put(raceId, await _calculate(raceId, window));
    } on Object catch (error) {
      _log('statisztika-frissítés sikertelen ($raceId): $error');
    }
  }

  Future<List<Race>> _finishedRaces() async => [
    for (final race in await _races.watchRaces().first)
      if (race.status == RaceStatus.finished) race,
  ];
}
