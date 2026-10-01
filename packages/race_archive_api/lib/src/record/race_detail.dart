import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:race_archive_api/src/race/archive_track_point.dart';
import 'package:race_archive_api/src/record/race_summary.dart';

/// A verseny-részletező adata (ADR 0048 D6 + Addendum 2 H4).
///
/// A [summary] mindkét fajtán ugyanaz, mint a napló sora. A [telemetry]
/// pontosan akkor van jelen, ha a verseny telemetriás.
///
/// Szándékosan nincs `==`: a domain `RoundingResult` nem értékszemantikájú,
/// így egy mező-szintű egyenlőség félrevezető lenne.
@immutable
final class RaceDetail {
  /// Részletező a [summary] versenyhez.
  const RaceDetail({required this.summary, this.telemetry});

  /// A napló-sor adatai: eredet, statisztika, eredmény.
  final RaceSummary summary;

  /// A telemetriás verseny térkép- és bója-adatai; kézinél `null`.
  final TelemetryRaceData? telemetry;
}

/// A telemetriás verseny részletezőjének adatai (ADR 0047 D4).
@immutable
final class TelemetryRaceData {
  /// A [race] versenyhez tartozó track és elemzés.
  const TelemetryRaceData({
    required this.race,
    required this.trackPoints,
    required this.roundings,
  });

  /// A befejezett verseny, a bójákkal és a megkerülési időkkel.
  final Race race;

  /// A track pontjai időrendben, ritkítás nélkül.
  final List<ArchiveTrackPoint> trackPoints;

  /// A megkerülésenkénti elemzés. A web nem jeleníti meg (ADR 0047
  /// Addendum 5 F1), a mező a szerződés része marad.
  final List<RoundingResult> roundings;
}
