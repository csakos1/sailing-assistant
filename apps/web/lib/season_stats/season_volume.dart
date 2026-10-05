import 'package:flutter/foundation.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A szezon mennyiségi mutatói (ADR 0049 D3 1.): versenyszám, vízen
/// töltött idő és táv.
///
/// A `null` mindenhol „nincs adat", nem nulla.
@immutable
class SeasonVolume {
  /// Mennyiség a megadott értékekkel.
  const SeasonVolume({
    required this.raceCount,
    required this.telemetryRaceCount,
    required this.manualRaceCount,
    required this.timeOnWater,
    required this.racesWithoutTime,
    required this.distanceMeters,
  });

  /// A versenyek száma.
  final int raceCount;

  /// Ebből a telefonról feltöltött, telemetriás versenyek.
  final int telemetryRaceCount;

  /// Ebből a kézi versenyek.
  final int manualRaceCount;

  /// A menetidők összege (`elapsedTimeOf`).
  final Duration? timeOnWater;

  /// Hány verseny maradt ki az időből, mert kézi, hivatalos idők nélkül.
  final int racesWithoutTime;

  /// A távok összege méterben.
  final double? distanceMeters;
}

/// Az [entries] versenyeinek mennyiségi mutatói.
SeasonVolume summarizeSeasonVolume(List<LogEntry> entries) {
  var telemetryRaceCount = 0;
  var racesWithoutTime = 0;
  Duration? timeOnWater;
  double? distanceMeters;
  for (final LogEntry(:summary) in entries) {
    if (summary.origin is TelemetryOrigin) telemetryRaceCount++;
    final elapsed = elapsedTimeOf(summary);
    if (elapsed == null) {
      racesWithoutTime++;
    } else {
      timeOnWater = (timeOnWater ?? Duration.zero) + elapsed.value;
    }
    final distance = summary.stats.track.distanceMeters;
    if (distance != null) distanceMeters = (distanceMeters ?? 0) + distance;
  }
  return SeasonVolume(
    raceCount: entries.length,
    telemetryRaceCount: telemetryRaceCount,
    manualRaceCount: entries.length - telemetryRaceCount,
    timeOnWater: timeOnWater,
    racesWithoutTime: racesWithoutTime,
    distanceMeters: distanceMeters,
  );
}
