import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:race_archive_api/src/annotation/annotation_codecs.dart';
import 'package:race_archive_api/src/annotation/race_annotation.dart';
import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/race/analysis_codecs.dart';
import 'package:race_archive_api/src/race/archive_track_point.dart';
import 'package:race_archive_api/src/race/archived_race_codec.dart';
import 'package:shared/shared.dart';

/// A verseny-részletező v1 adata (ADR 0047 D4 + Addendum 1 A5).
///
/// A v2 `RaceDetail` mellett az S5b-3-ig él, amíg a szerver át nem áll
/// (ADR 0048 Addendum 2 H6); utána törlődik.
///
/// A szerver ugyanazokkal a domain use case-ekkel állítja elő, mint a phone
/// `post_race_analysis_provider`-e. A `RoundingSummary` nincs benne: a web
/// a `SummarizeRoundings`-szal számolja a [roundings]-ból, mert származtatott
/// adatot nem küldünk kétszer.
///
/// Szándékosan nincs `==`: a domain `RoundingResult` nem értékszemantikájú,
/// így egy mező-szintű egyenlőség félrevezető lenne.
@immutable
final class LegacyRaceDetail {
  /// Részletező a [race]-hez.
  const LegacyRaceDetail({
    required this.race,
    required this.trackStats,
    required this.trackPoints,
    required this.roundings,
    this.annotation,
  });

  /// A befejezett verseny, a bójákkal és a megkerülési időkkel.
  final Race race;

  /// Max- és átlagsebesség, megtett út.
  final TrackStats trackStats;

  /// A track pontjai időrendben, ritkítás nélkül (D4).
  final List<ArchiveTrackPoint> trackPoints;

  /// A megkerülésenkénti elemzés (`AnalyzeRoundings`).
  final List<RoundingResult> roundings;

  /// Az eredmény-adatok; `null`, ha még nincs rögzítve.
  final RaceAnnotation? annotation;
}

/// A `GET /api/races/{id}` v1 válasza.
Map<String, Object?> encodeLegacyRaceDetail(LegacyRaceDetail detail) =>
    <String, Object?>{
      'race': encodeArchivedRace(detail.race),
      'trackStats': encodeTrackStats(detail.trackStats),
      'trackPoints': [
        for (final point in detail.trackPoints) encodeTrackPoint(point),
      ],
      'roundings': [
        for (final result in detail.roundings) encodeRoundingResult(result),
      ],
      'annotation': switch (detail.annotation) {
        null => null,
        final RaceAnnotation annotation => encodeRaceAnnotation(annotation),
      },
    };

/// JSON → [LegacyRaceDetail].
Result<LegacyRaceDetail, DecodeError> decodeLegacyRaceDetail(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      final annotation = reader.optionalObject('annotation');
      return LegacyRaceDetail(
        race: readArchivedRace(reader.object('race')),
        trackStats: readTrackStats(reader.object('trackStats')),
        trackPoints: reader.list('trackPoints', readTrackPoint),
        roundings: reader.list('roundings', readRoundingResult),
        annotation: annotation == null ? null : readRaceAnnotation(annotation),
      );
    });
