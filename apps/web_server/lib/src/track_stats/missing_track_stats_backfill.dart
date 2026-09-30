import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:web_server/src/server_log.dart';

/// A hiányzó `race_track_stats` sorok pótlása az archívumban (ADR 0047
/// Addendum 3 C7).
///
/// A telefon a sort lustán, a napló megnyitásakor írja, ezért egy lehúzott
/// DB-ből a frissen befejezett versenyek sora hiányozhat. Az importer a
/// merge után, a saját mutex-én belül hívja: az archívumba csak az importer
/// ír, így utána minden archivált versenynek van sora, és a napló `GET`-je
/// tiszta olvasás maradhat.
///
/// A projekciós `TrackSampleReaderImpl`-t használja, ugyanazt, mint a phone
/// napló-összesítője: soronként három szám jön át, nem a teljes JSON.
class MissingTrackStatsBackfill {
  /// Pótlás az [archive]-ban; a `computedAt` a [now]-ból jön.
  MissingTrackStatsBackfill({
    required AppDatabase archive,
    DateTime Function() now = DateTime.now,
    ServerLog log = ignoreServerLog,
  }) : _archive = archive,
       _now = now,
       _log = log,
       _readSamples = TrackSampleReaderImpl(archive).call,
       _writeStats = RaceTrackStatsRepositoryImpl(archive).write;

  final AppDatabase _archive;
  final DateTime Function() _now;
  final ServerLog _log;
  final TrackSampleReader _readSamples;
  final RaceTrackStatsWriter _writeStats;

  static const _summarize = SummarizeTrack();

  /// A pótolt versenyek azonosítói.
  ///
  /// Egy verseny hibája nem állítja meg a többit: a merge ekkor már
  /// lezárult, és egy hiányzó sort a napló védőága úgyis kiszámol. A hibát
  /// naplózza, a következő import újrapróbálja.
  Future<List<String>> call() async {
    final filled = <String>[];
    for (final raceId in await _racesWithoutStats()) {
      try {
        final samples = await _readSamples(raceId);
        await _writeStats(
          raceId,
          _summarize(samples),
          sampleCount: samples.length,
          computedAt: _now(),
        );
        filled.add(raceId);
      } on Object catch (error) {
        _log('track-stat pótlás sikertelen ($raceId): $error');
      }
    }
    return filled;
  }

  Future<List<String>> _racesWithoutStats() async {
    final races = _archive.races;
    final stats = _archive.raceTrackStats;
    final query =
        _archive.select(races).join([
          leftOuterJoin(stats, stats.raceId.equalsExp(races.id)),
        ])..where(
          stats.raceId.isNull() &
              races.statusIndex.equalsValue(RaceStatus.finished),
        );
    final rows = await query.get();
    return [for (final row in rows) row.readTable(races).id];
  }
}
