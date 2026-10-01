import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/race/race_summaries.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/stats/telemetry_stats_resolver.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

/// A versenynapló: a telemetriás és a kézi versenyek napló-sorai (ADR 0048
/// D6 + Addendum 3 I6).
///
/// A két DB join-ja itt, Dartban történik (ADR 0047 D5). Tiszta olvasás:
/// a statisztika a cache-ből jön, egy hiányzó sort a feloldó memóriában
/// számol (I4).
class RaceSummaryService {
  /// Szolgáltatás az archívum [races] olvasójával és a webes tárakkal.
  RaceSummaryService({
    required RaceRepository races,
    required RaceResultRepository results,
    required RaceStatsRepository stats,
    required ManualRaceRepository manualRaces,
    required TelemetryStatsResolver resolveStats,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _results = results,
       _stats = stats,
       _manualRaces = manualRaces,
       _resolveStats = resolveStats,
       _log = log;

  final RaceRepository _races;
  final RaceResultRepository _results;
  final RaceStatsRepository _stats;
  final ManualRaceRepository _manualRaces;
  final TelemetryStatsResolver _resolveStats;
  final ServerLog _log;

  /// A napló sorai, a legújabbal kezdve.
  Future<List<RaceSummary>> call() async {
    final results = await _results.getAll();
    final cached = await _stats.getAll();
    final summaries = <RaceSummary>[
      ...await _telemetrySummaries(results, cached),
      for (final record in await _manualRaces.getAll())
        manualSummaryOf(record, results[record.id]),
    ]..sort(compareNewestFirst);
    return summaries;
  }

  Future<List<RaceSummary>> _telemetrySummaries(
    Map<String, RaceResult> results,
    Map<String, CachedRaceStats> cached,
  ) async {
    final summaries = <RaceSummary>[];
    for (final race in await _races.watchRaces().first) {
      if (race.status != RaceStatus.finished) continue;
      final recording = recordingWindowOf(race);
      if (recording == null) {
        _log('a verseny rögzítési ablaka hiányos (${race.id}): kihagyva');
        continue;
      }
      final result = results[race.id];
      final expected = expectedStatsWindow(
        recording: recording,
        result: result?.content,
      );
      summaries.add(
        telemetrySummaryOf(
          race: race,
          recording: recording,
          stats: await _resolveStats(race.id, expected, cached[race.id]),
          result: result,
        ),
      );
    }
    return summaries;
  }
}
