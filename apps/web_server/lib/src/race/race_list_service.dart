import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/annotation/annotation_repository.dart';
import 'package:web_server/src/server_log.dart';

/// A versenynapló adatai: a befejezett versenyek a track-statisztikával
/// és az annotációval (ADR 0047 Addendum 1 A5 + Addendum 3 C8).
///
/// A két DB join-ja itt, Dartban történik (D5). Tiszta olvasás: a hiányzó
/// track-stat sort az import pótolja (C7). Ha mégis hiányzik, a védőág
/// memóriában számol, **nem ír vissza**, és naplóz, mert ez azt jelenti,
/// hogy az import pótlása elbukott.
class RaceListService {
  /// Szolgáltatás az archívum olvasóival és az [annotations]-szal.
  RaceListService({
    required RaceRepository races,
    required RaceTrackStatsReader readTrackStats,
    required TrackSampleReader readTrackSamples,
    required AnnotationRepository annotations,
    ServerLog log = ignoreServerLog,
  }) : _races = races,
       _readTrackStats = readTrackStats,
       _readTrackSamples = readTrackSamples,
       _annotations = annotations,
       _log = log;

  final RaceRepository _races;
  final RaceTrackStatsReader _readTrackStats;
  final TrackSampleReader _readTrackSamples;
  final AnnotationRepository _annotations;
  final ServerLog _log;

  static const _summarize = SummarizeTrack();

  /// A napló elemei, a legutóbb befejezett versennyel kezdve.
  Future<List<RaceListItem>> call() async {
    final races = await _finishedRacesNewestFirst();
    final annotations = await _annotations.getAll();
    return [
      for (final race in races)
        RaceListItem(
          race: race,
          trackStats: await _trackStatsOf(race.id),
          annotation: annotations[race.id],
        ),
    ];
  }

  Future<List<Race>> _finishedRacesNewestFirst() async {
    final all = await _races.watchRaces().first;
    final finished = [
      for (final race in all)
        if (race.status == RaceStatus.finished) race,
    ];
    // A befejezett verseny invariánsa szerint a finishedAt nem null; az
    // összehasonlítás ennek ellenére védekező, egy sérült sor ne dobjon.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    finished.sort(
      (a, b) => (b.finishedAt ?? epoch).compareTo(a.finishedAt ?? epoch),
    );
    return finished;
  }

  Future<TrackStats> _trackStatsOf(String raceId) async {
    final cached = await _readTrackStats(raceId);
    if (cached != null) return cached;
    _log('hiányzó race_track_stats sor ($raceId): memóriában számolva');
    return _summarize(await _readTrackSamples(raceId));
  }
}
