import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// Egy telemetriás verseny tárolt statisztikája (ADR 0048 D4 + Addendum 3
/// I4).
///
/// A [window] csak `OfficialWindow` vagy `RecordingWindow` lehet: kézi
/// versenynek nincs cache-sora (I2).
final class CachedRaceStats extends Equatable {
  /// Statisztika a [window] ablakból, [computedAt]-kor számolva.
  const CachedRaceStats({
    required this.window,
    required this.track,
    required this.wind,
    required this.computedAt,
  });

  /// Az ablak, amelyből számolódott.
  final StatsWindow window;

  /// Táv, átlag- és max. sebesség.
  final TrackStats track;

  /// Átlagos és max. szél, uralkodó irány fokban.
  final WindStats wind;

  /// A számítás ideje (UTC).
  final DateTime computedAt;

  /// A szerződés alakja: az irány égtájra képezve (Addendum 2 H1).
  RaceStats toRaceStats() => RaceStats(
    window: window,
    track: track,
    avgWindMps: wind.avgWindMps,
    maxWindMps: wind.maxWindMps,
    windPoint: switch (wind.directionDeg) {
      null => null,
      final double degrees => CompassPoint.fromDegrees(degrees),
    },
  );

  @override
  List<Object?> get props => [window, track, wind, computedAt];
}
