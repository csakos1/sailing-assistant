import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';

/// A szezon mennyiségi mutatói a csíkhoz (ADR 0049 D3 1., Addendum 2 R2):
/// versenyszám, vízen töltött idő és táv.
///
/// A `null` mindenhol „nincs adat", nem nulla.
@immutable
class SeasonVolume {
  /// Mennyiség a megadott értékekkel.
  const SeasonVolume({
    required this.raceCount,
    required this.timeOnWater,
    required this.distanceMeters,
  });

  /// A versenyek száma, a DNF-fel és a helyezés nélküliekkel együtt.
  final int raceCount;

  /// A menetidők összege (`elapsedTimeOf`).
  final Duration? timeOnWater;

  /// A távok összege méterben.
  final double? distanceMeters;
}

/// Az [entries] versenyeinek mennyiségi mutatói.
SeasonVolume summarizeSeasonVolume(List<LogEntry> entries) {
  Duration? timeOnWater;
  double? distanceMeters;
  for (final LogEntry(:summary) in entries) {
    final elapsed = elapsedTimeOf(summary);
    if (elapsed != null) {
      timeOnWater = (timeOnWater ?? Duration.zero) + elapsed.value;
    }
    final distance = summary.stats.track.distanceMeters;
    if (distance != null) distanceMeters = (distanceMeters ?? 0) + distance;
  }
  return SeasonVolume(
    raceCount: entries.length,
    timeOnWater: timeOnWater,
    distanceMeters: distanceMeters,
  );
}
