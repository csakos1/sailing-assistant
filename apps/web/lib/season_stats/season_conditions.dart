import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/season_stats/season_record.dart';
import 'package:foretack_web/season_stats/wind_band.dart';

/// A szezon pálya-mutatói és a szélsávok (ADR 0049 Addendum 2 R2, R5).
@immutable
class SeasonConditions {
  /// Mutatók a megadott értékekkel.
  const SeasonConditions({
    required this.avgSpeedMps,
    required this.longestRace,
    required this.fastestAverageRace,
    required this.fastestRace,
    required this.windiestRace,
    required this.prevailingWindPoints,
    required this.windBandCounts,
  });

  /// A táv és az idő összegének hányadosa, csak azokon a versenyeken,
  /// ahol mindkettő megvan; `null`, ha egy ilyen sincs.
  final double? avgSpeedMps;

  /// A leghosszabb táv versenye (méter).
  final SeasonRecord? longestRace;

  /// A legnagyobb átlagsebességű verseny (m/s).
  final SeasonRecord? fastestAverageRace;

  /// A legnagyobb max. sebesség versenye (m/s).
  final SeasonRecord? fastestRace;

  /// A legnagyobb max. szél versenye (m/s).
  final SeasonRecord? windiestRace;

  /// A leggyakoribb égtáj; holtversenynél mind, égtáj-sorrendben. Üres,
  /// ha egy versenynek sincs iránya.
  final List<CompassPoint> prevailingWindPoints;

  /// A versenyek száma átlagszél-sávonként; minden sáv kulcs, a sávok
  /// sorrendjében.
  final Map<WindBand, int> windBandCounts;
}

/// Az [entries] versenyeinek pálya-mutatói.
///
/// Döntetlen rekordnál a lista korábbi (a napló sorrendjében újabb)
/// versenye marad (R5).
SeasonConditions summarizeSeasonConditions(List<LogEntry> entries) {
  var timedDistanceMeters = 0.0;
  var timedDuration = Duration.zero;
  SeasonRecord? longestRace;
  SeasonRecord? fastestAverageRace;
  SeasonRecord? fastestRace;
  SeasonRecord? windiestRace;
  final windPointCounts = <CompassPoint, int>{};
  final windBandCounts = {for (final band in WindBand.values) band: 0};
  for (final entry in entries) {
    final stats = entry.summary.stats;
    final distance = stats.track.distanceMeters;
    final elapsed = elapsedTimeOf(entry.summary);
    if (distance != null && elapsed != null) {
      timedDistanceMeters += distance;
      timedDuration += elapsed.value;
    }
    longestRace = _higherRecord(longestRace, entry, distance);
    fastestAverageRace = _higherRecord(
      fastestAverageRace,
      entry,
      stats.track.avgSpeedMps,
    );
    fastestRace = _higherRecord(fastestRace, entry, stats.track.maxSpeedMps);
    windiestRace = _higherRecord(windiestRace, entry, stats.maxWindMps);
    final windPoint = stats.windPoint;
    if (windPoint != null) {
      windPointCounts.update(
        windPoint,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final avgWind = stats.avgWindMps;
    if (avgWind != null) {
      windBandCounts.update(
        WindBand.ofMetersPerSecond(avgWind),
        (count) => count + 1,
      );
    }
  }
  final timedSeconds = timedDuration.inMilliseconds / 1000;
  return SeasonConditions(
    avgSpeedMps: timedSeconds > 0 ? timedDistanceMeters / timedSeconds : null,
    longestRace: longestRace,
    fastestAverageRace: fastestAverageRace,
    fastestRace: fastestRace,
    windiestRace: windiestRace,
    prevailingWindPoints: _mostFrequent(windPointCounts),
    windBandCounts: Map.unmodifiable(windBandCounts),
  );
}

// A [current] rekord, vagy az [entry] versenye, ha a [value] nagyobb.
SeasonRecord? _higherRecord(
  SeasonRecord? current,
  LogEntry entry,
  double? value,
) {
  if (value == null) return current;
  if (current != null && value <= current.value) return current;
  return (value: value, raceName: entry.summary.name, day: entry.day);
}

// A leggyakoribb égtájak, égtáj-sorrendben.
List<CompassPoint> _mostFrequent(Map<CompassPoint, int> counts) {
  var highest = 0;
  for (final count in counts.values) {
    if (count > highest) highest = count;
  }
  return List.unmodifiable([
    for (final point in CompassPoint.values)
      if (highest > 0 && counts[point] == highest) point,
  ]);
}
