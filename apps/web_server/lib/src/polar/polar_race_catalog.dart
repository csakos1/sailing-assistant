import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/budapest_time.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

/// A polár-statisztikás versenyek listája (ADR 0049 Addendum 4 U3).
///
/// Telemetriás: minden befejezett verseny érvényes rögzítési ablakkal, a
/// `race_stats` ablakával. Régi: a trackes kézi verseny érvényes
/// hivatalos ablakkal. Minden hívás frissen olvas, mert egy import vagy
/// mentés bármikor változtathat a listán.
class PolarRaceCatalog {
  /// Katalógus az archívum [races] olvasójával és a webes tárakkal.
  PolarRaceCatalog({
    required RaceRepository races,
    required RaceResultRepository results,
    required ManualRaceRepository manualRaces,
    required LegacyTrackRepository tracks,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _results = results,
       _manualRaces = manualRaces,
       _tracks = tracks,
       _log = log;

  final RaceRepository _races;
  final RaceResultRepository _results;
  final ManualRaceRepository _manualRaces;
  final LegacyTrackRepository _tracks;
  final ServerLog _log;

  /// Az összes polár-statisztikás verseny, rendezetlenül.
  Future<List<PolarRace>> all() async {
    final results = await _results.getAll();
    return [
      ...await _telemetryRaces(results),
      ...await _legacyRaces(results),
    ];
  }

  /// A [raceId] verseny, vagy `null`, ha nincs polár-forrása.
  Future<PolarRace?> byId(String raceId) async {
    for (final race in await all()) {
      if (race.id == raceId) return race;
    }
    return null;
  }

  Future<List<PolarRace>> _telemetryRaces(
    Map<String, RaceResult> results,
  ) async {
    final polarRaces = <PolarRace>[];
    for (final race in await _races.watchRaces().first) {
      if (race.status != RaceStatus.finished) continue;
      final recording = recordingWindowOf(race);
      if (recording == null) {
        _log('a verseny rögzítési ablaka hiányos (${race.id}): kihagyva');
        continue;
      }
      final content = results[race.id]?.content;
      final start = content?.officialStart ?? recording.start;
      polarRaces.add(
        PolarRace(
          id: race.id,
          name: race.name,
          source: PolarSampleSource.telemetry,
          expectedWindow: expectedStatsWindow(
            recording: recording,
            result: content,
          ),
          day: budapestDayOf(start),
          startInstant: start,
          elapsed: _positive(content?.officialElapsed) ?? recording.duration,
        ),
      );
    }
    return polarRaces;
  }

  Future<List<PolarRace>> _legacyRaces(
    Map<String, RaceResult> results,
  ) async {
    final withTrack = await _tracks.raceIdsWithTrack();
    return [
      for (final record in await _manualRaces.getAll())
        if (withTrack.contains(record.id))
          if (officialWindowOf(results[record.id]?.content)
              case final TimeWindow official)
            PolarRace(
              id: record.id,
              name: record.input.name,
              source: PolarSampleSource.legacyTrack,
              expectedWindow: OfficialWindow(official),
              day: record.input.date,
              startInstant: official.start,
              elapsed: official.duration,
            ),
    ];
  }

  // A hivatalos menetidő csak pozitívként érvényes (ADR 0048 D4).
  static Duration? _positive(Duration? elapsed) =>
      elapsed != null && elapsed > Duration.zero ? elapsed : null;
}
