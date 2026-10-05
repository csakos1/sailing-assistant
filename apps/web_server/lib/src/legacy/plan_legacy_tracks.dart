import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// A track-import terve: minden kézi versenyre, mi lesz a tracke (ADR
/// 0050 D2, D4 + Addendum 1 E4).
///
/// A [tracks] a CSV kivágása versenyenként (`sliceYdvrCsv`). A terv a
/// teljes állapotot írja le: a track nélküli tétel végrehajtáskor a
/// korábbi tracket törli. A sorrend a nap, azon belül a név, hogy a kiírás
/// a napló sorrendjét kövesse.
///
/// Pure: ugyanarra a bemenetre ugyanazt a tervet adja.
List<LegacyTrackPlanItem> planLegacyTracks({
  required List<ManualRaceRecord> manualRaces,
  required Map<String, RaceResult> results,
  required Map<String, List<LegacyTrackSample>> tracks,
}) {
  final sorted = [...manualRaces]..sort(_byDateThenName);
  return [
    for (final race in sorted)
      _itemOf(race, results[race.id], tracks[race.id] ?? const []),
  ];
}

const _summarizeTrack = SummarizeTrack();

LegacyTrackPlanItem _itemOf(
  ManualRaceRecord race,
  RaceResult? result,
  List<LegacyTrackSample> samples,
) {
  final window = officialWindowOf(result?.content);
  if (window == null) return LegacyTrackWithoutWindow(race);
  final positionCount = samples
      .where((sample) => sample.latDeg != null && sample.lonDeg != null)
      .length;
  if (positionCount < 2) {
    return LegacyTrackTooShort(
      race,
      window: window,
      sampleCount: samples.length,
      positionCount: positionCount,
    );
  }
  return PlannedLegacyTrack(
    race,
    window: window,
    samples: samples,
    coverage: _coverageOf(samples.length, window),
    distanceMeters: _summarizeTrack(samples).distanceMeters,
  );
}

// A hivatalos ablak pozitív hosszú (officialWindowOf), így nincs nullával
// osztás.
double _coverageOf(int sampleCount, TimeWindow window) {
  final ratio =
      sampleCount *
      legacySampleSeconds *
      Duration.millisecondsPerSecond /
      window.duration.inMilliseconds;
  if (ratio > 1) return 1;
  return ratio;
}

int _byDateThenName(ManualRaceRecord a, ManualRaceRecord b) {
  final byDate = a.input.date.compareTo(b.input.date);
  return byDate != 0 ? byDate : a.input.name.compareTo(b.input.name);
}
