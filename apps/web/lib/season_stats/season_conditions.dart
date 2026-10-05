import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/season_record.dart';
import 'package:foretack_web/season_stats/wind_band.dart';

/// A szezon sebesség- és szél-mutatói (ADR 0049 D3 3., Addendum 1 P3,
/// P4).
@immutable
class SeasonConditions {
  /// Mutatók a megadott értékekkel.
  const SeasonConditions({
    required this.avgSpeedMps,
    required this.fastestRace,
    required this.windiestRace,
    required this.windBandCounts,
    required this.racesWithoutWind,
  });

  /// A táv és az idő összegének hányadosa, csak azokon a versenyeken,
  /// ahol mindkettő megvan; `null`, ha egy ilyen sincs.
  final double? avgSpeedMps;

  /// A legnagyobb max. sebesség versenye.
  final SeasonRecord? fastestRace;

  /// A legnagyobb max. szél versenye.
  final SeasonRecord? windiestRace;

  /// A versenyek száma átlagszél-sávonként; minden sáv kulcs, a sávok
  /// sorrendjében.
  final Map<WindBand, int> windBandCounts;

  /// Hány versenyen nincs átlagszél.
  final int racesWithoutWind;
}

/// Az [entries] versenyeinek sebesség- és szél-mutatói.
///
/// Döntetlen rekordnál a lista korábbi (a napló sorrendjében újabb)
/// versenye marad (P4).
SeasonConditions summarizeSeasonConditions(List<LogEntry> entries) {
  var timedDistanceMeters = 0.0;
  var timedDuration = Duration.zero;
  SeasonRecord? fastestRace;
  SeasonRecord? windiestRace;
  final windBandCounts = {for (final band in WindBand.values) band: 0};
  var racesWithoutWind = 0;
  for (final entry in entries) {
    final stats = entry.summary.stats;
    final distance = stats.track.distanceMeters;
    final elapsed = elapsedTimeOf(entry.summary);
    if (distance != null && elapsed != null) {
      timedDistanceMeters += distance;
      timedDuration += elapsed.value;
    }
    fastestRace = _higherRecord(fastestRace, entry, stats.track.maxSpeedMps);
    windiestRace = _higherRecord(windiestRace, entry, stats.maxWindMps);
    final avgWind = stats.avgWindMps;
    if (avgWind == null) {
      racesWithoutWind++;
    } else {
      windBandCounts.update(
        WindBand.ofMetersPerSecond(avgWind),
        (count) => count + 1,
      );
    }
  }
  final timedSeconds = timedDuration.inMilliseconds / 1000;
  return SeasonConditions(
    avgSpeedMps: timedSeconds > 0 ? timedDistanceMeters / timedSeconds : null,
    fastestRace: fastestRace,
    windiestRace: windiestRace,
    windBandCounts: Map.unmodifiable(windBandCounts),
    racesWithoutWind: racesWithoutWind,
  );
}

// A [current] rekord, vagy az [entry] versenye, ha a [valueMps] nagyobb.
SeasonRecord? _higherRecord(
  SeasonRecord? current,
  LogEntry entry,
  double? valueMps,
) {
  if (valueMps == null) return current;
  if (current != null && valueMps <= current.valueMps) return current;
  return (valueMps: valueMps, raceName: entry.summary.name, day: entry.day);
}
