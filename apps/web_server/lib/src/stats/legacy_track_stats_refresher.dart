import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';

/// A trackes kézi versenyek `race_stats` cache-ének frissítése (ADR 0050
/// D5 + Addendum 1 E2).
///
/// A telemetriás `RaceStatsRefresher` mellett él, hogy az változatlan
/// maradjon (OCP). A [RaceStatsCalculator] itt a régi trackből olvas.
///
/// **Várt ablak:** `OfficialWindow`, ha a kézi versenynek van tracke, és
/// a hivatalos ablaka érvényes; különben a versenynek nincs számolt
/// statja, és egy meglévő sora törlődik (a beírt számok érvényesek).
///
/// A szerveren a hívó a közös `SerialLock` alatt hívja (I5); a CLI-ben a
/// szerver áll. Egy verseny hibája nem állítja meg a többit: naplózza.
class LegacyTrackStatsRefresher {
  /// Frissítő a webes tárakkal és a régi trackből számoló [calculate]-tel.
  LegacyTrackStatsRefresher({
    required ManualRaceRepository manualRaces,
    required RaceResultRepository results,
    required LegacyTrackRepository tracks,
    required RaceStatsRepository stats,
    required RaceStatsCalculator calculate,
    ServerLog log = ignoreServerLog,
  }) : _manualRaces = manualRaces,
       _results = results,
       _tracks = tracks,
       _stats = stats,
       _calculate = calculate,
       _log = log;

  final ManualRaceRepository _manualRaces;
  final RaceResultRepository _results;
  final LegacyTrackRepository _tracks;
  final RaceStatsRepository _stats;
  final RaceStatsCalculator _calculate;
  final ServerLog _log;

  /// A track-import után: minden trackes kézi verseny statja újraszámolódik
  /// akkor is, ha az ablaka nem változott, mert a track tartalma igen. A
  /// track nélküliek sora törlődik.
  Future<void> refreshAll() async {
    final results = await _results.getAll();
    final withTrack = await _tracks.raceIdsWithTrack();
    for (final race in await _manualRaces.getAll()) {
      final expected = _expectedWindowOf(
        hasTrack: withTrack.contains(race.id),
        result: results[race.id]?.content,
      );
      await _apply(race.id, expected, isForced: true);
    }
  }

  /// A kézi verseny mentése után: a [raceId] statja, ha a várt ablak
  /// eltér a tárolttól. Telemetriás vagy ismeretlen azonosítóra nem tesz
  /// semmit.
  ///
  /// A versenyt és az eredményt maga olvassa vissza, így a legutóbbi
  /// mentés állapota számít, nem a hívóé.
  Future<void> refreshIfStale(String raceId) async {
    if (await _manualRaces.get(raceId) == null) return;
    final result = await _results.get(raceId);
    final expected = _expectedWindowOf(
      hasTrack: await _tracks.hasTrack(raceId),
      result: result?.content,
    );
    await _apply(raceId, expected, isForced: false);
  }

  OfficialWindow? _expectedWindowOf({
    required bool hasTrack,
    required RaceResultInput? result,
  }) {
    if (!hasTrack) return null;
    return switch (officialWindowOf(result)) {
      null => null,
      final TimeWindow window => OfficialWindow(window),
    };
  }

  Future<void> _apply(
    String raceId,
    OfficialWindow? expected, {
    required bool isForced,
  }) async {
    try {
      final cached = await _stats.get(raceId);
      if (expected == null) {
        if (cached != null) await _stats.delete(raceId);
        return;
      }
      if (!isForced && cached?.window == expected) return;
      await _stats.put(raceId, await _calculate(raceId, expected));
    } on Object catch (error) {
      _log('a régi track statisztikája sikertelen ($raceId): $error');
    }
  }
}
