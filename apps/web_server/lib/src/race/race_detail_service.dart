import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/annotation/annotation_repository.dart';

/// Egy befejezett verseny részletezője (ADR 0047 D4 + Addendum 3 C8).
///
/// Ugyanazokat a use case-eket futtatja ugyanabban a sorrendben, mint a
/// phone `post_race_analysis_provider`-e, így a két felület számai
/// definíció szerint egyeznek. A `SummarizeRoundings` nincs itt: azt a web
/// számolja a `roundings`-ból (D4).
class RaceDetailService {
  /// Szolgáltatás az archívum olvasóival és az [annotations]-szal.
  RaceDetailService({
    required RaceRepository races,
    required RoundingSampleReader readRoundingSamples,
    required AnnotationRepository annotations,
  }) : _races = races,
       _readRoundingSamples = readRoundingSamples,
       _annotations = annotations;

  final RaceRepository _races;
  final RoundingSampleReader _readRoundingSamples;
  final AnnotationRepository _annotations;

  static const _analyzeRoundings = AnalyzeRoundings();
  static const _summarizeTrack = SummarizeTrack();

  /// A [raceId] verseny részletezője, vagy `null`, ha nincs ilyen
  /// befejezett verseny.
  Future<LegacyRaceDetail?> call(String raceId) async {
    final race = await _races.getRace(raceId);
    // Az archívumban csak befejezett verseny van (D6); egy mégis
    // befejezetlen sort a szerződés nem tud leírni (Addendum 1 A3).
    if (race == null || race.status != RaceStatus.finished) return null;

    final samples = await _readRoundingSamples(raceId);
    return LegacyRaceDetail(
      race: race,
      trackStats: _summarizeTrack(samples),
      trackPoints: _trackPointsOf(samples),
      roundings: _analyzeRoundings(samples),
      annotation: await _annotations.get(raceId),
    );
  }

  // A pozíció nélküli minták kimaradnak, a sebesség nélküliek nem: a
  // színezés a hiányzó SOG-ot külön kezeli (phone ADR 0034 Addendum 4).
  List<ArchiveTrackPoint> _trackPointsOf(List<RoundingSample> samples) => [
    for (final sample in samples)
      if (sample.latDeg case final lat?)
        if (sample.lonDeg case final lon?)
          ArchiveTrackPoint(
            position: Coordinate(latitude: lat, longitude: lon),
            sogMps: sample.sogMps,
          ),
  ];
}
