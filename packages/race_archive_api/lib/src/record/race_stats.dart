import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:race_archive_api/src/record/stats_window.dart';

/// Egy verseny táv-, sebesség- és szél-statisztikája (ADR 0048 D4, D5 +
/// Addendum 2 H1, H3).
///
/// A szerver számolja (telemetriásnál a [window] mintáiból, kézinél a
/// beírt értékekből), a web csak megjeleníti. A `null` mindenhol „nincs
/// adat", nem nulla.
final class RaceStats extends Equatable {
  /// Statisztika a [window] ablakból.
  const RaceStats({
    required this.window,
    this.track = const TrackStats(),
    this.avgWindMps,
    this.maxWindMps,
    this.windPoint,
  });

  /// Melyik mintákból készült.
  final StatsWindow window;

  /// Táv, átlag- és max. sebesség. Kézi versenyen az átlag a táv ÷
  /// menetidő.
  final TrackStats track;

  /// Az átlagos valós szél m/s-ben.
  final double? avgWindMps;

  /// A legnagyobb valós szél m/s-ben.
  final double? maxWindMps;

  /// Az uralkodó szélirány égtájként.
  final CompassPoint? windPoint;

  @override
  List<Object?> get props => [
    window,
    track,
    avgWindMps,
    maxWindMps,
    windPoint,
  ];
}
