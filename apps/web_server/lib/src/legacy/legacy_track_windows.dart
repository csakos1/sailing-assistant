import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/legacy/legacy_track_window.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

/// A [manualRaces] hivatalos ablakai a [results] eredményeiből (ADR 0050
/// D2).
///
/// Csak a mindkét hivatalos idővel, a rajtnál későbbi befutással bíró kézi
/// verseny kap ablakot; a hivatalos idő nélküli és a DNF (befutás nélküli)
/// kimarad.
List<LegacyTrackWindow> legacyTrackWindowsOf({
  required List<ManualRaceRecord> manualRaces,
  required Map<String, RaceResult> results,
}) => [
  for (final race in manualRaces)
    if (officialWindowOf(results[race.id]?.content) case final window?)
      (raceId: race.id, window: window),
];
