import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/race/race_summaries.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/stats/telemetry_stats_resolver.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

/// Egy verseny részletezője, telemetriás vagy kézi (ADR 0047 D4, ADR 0048
/// D6 + Addendum 2 H4).
///
/// A telemetriás versenyen ugyanazokat a use case-eket futtatja ugyanabban
/// a sorrendben, mint a phone `post_race_analysis_provider`-e, így a két
/// felület számai definíció szerint egyeznek. A track a teljes rögzítés
/// (Addendum 1 G3, a térkép a teljes trackre áll); csak a statisztika
/// ablakos.
class RaceDetailService {
  /// Szolgáltatás az archívum olvasóival és a webes tárakkal.
  RaceDetailService({
    required RaceRepository races,
    required RoundingSampleReader readRoundingSamples,
    required RaceResultRepository results,
    required RaceStatsRepository stats,
    required ManualRaceRepository manualRaces,
    required TelemetryStatsResolver resolveStats,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _readRoundingSamples = readRoundingSamples,
       _results = results,
       _stats = stats,
       _manualRaces = manualRaces,
       _resolveStats = resolveStats,
       _log = log;

  final RaceRepository _races;
  final RoundingSampleReader _readRoundingSamples;
  final RaceResultRepository _results;
  final RaceStatsRepository _stats;
  final ManualRaceRepository _manualRaces;
  final TelemetryStatsResolver _resolveStats;
  final ServerLog _log;

  static const _analyzeRoundings = AnalyzeRoundings();

  /// A [raceId] verseny részletezője, vagy `null`, ha nincs ilyen
  /// befejezett telemetriás vagy kézi verseny.
  Future<RaceDetail?> call(String raceId) async {
    final race = await _races.getRace(raceId);
    // Az archívumban csak befejezett verseny van (ADR 0047 D6); egy mégis
    // befejezetlen sort a szerződés nem tud leírni (Addendum 1 A3).
    if (race != null && race.status == RaceStatus.finished) {
      return _telemetryDetail(race);
    }
    final record = await _manualRaces.get(raceId);
    if (record == null) return null;
    return RaceDetail(
      summary: manualSummaryOf(record, await _results.get(raceId)),
    );
  }

  Future<RaceDetail?> _telemetryDetail(Race race) async {
    final recording = recordingWindowOf(race);
    if (recording == null) {
      _log('a verseny rögzítési ablaka hiányos (${race.id}): nem leírható');
      return null;
    }
    final result = await _results.get(race.id);
    final expected = expectedStatsWindow(
      recording: recording,
      result: result?.content,
    );
    final stats = await _resolveStats(
      race.id,
      expected,
      await _stats.get(race.id),
    );
    final samples = await _readRoundingSamples(race.id);
    return RaceDetail(
      summary: telemetrySummaryOf(
        race: race,
        recording: recording,
        stats: stats,
        result: result,
      ),
      telemetry: TelemetryRaceData(
        race: race,
        trackPoints: _trackPointsOf(samples),
        roundings: _analyzeRoundings(samples),
      ),
    );
  }

  // A pozíció nélküli minták kimaradnak, a sebesség nélküliek nem: a
  // színezés a hiányzó SOG-ot külön kezeli (phone ADR 0034 Addendum 4).
  List<ArchiveTrackPoint> _trackPointsOf(List<RoundingSample> samples) => [
    for (final sample in samples)
      if (sample.latDeg case final lat?)
        if (sample.lonDeg case final lon?)
          ArchiveTrackPoint(
            position: Coordinate(latitude: lat, longitude: lon),
            sogMps: sample.sogMps,
          ),
  ];
}
