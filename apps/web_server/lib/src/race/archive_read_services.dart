import 'package:data/data.dart';
import 'package:web_server/src/race/race_detail_service.dart';
import 'package:web_server/src/race/race_summary_service.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/stats/telemetry_stats_resolver.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';
import 'package:web_server/src/web_db/race_stats_repository.dart';
import 'package:web_server/src/web_db/web_database.dart';

/// A napló és a részletező olvasó szolgáltatásai egy archívum- és egy
/// webes DB fölött (ADR 0050 Addendum 3 G3).
///
/// Egy helyen rakja össze őket, hogy az élő végpontok és az export a két
/// DB pillanatképéből ugyanazokkal a szolgáltatásokkal, ugyanazokat a
/// sorokat adják.
final class ArchiveReadServices {
  ArchiveReadServices._(this.summaries, this.details);

  /// A szolgáltatások az [archive] és a [webDatabase] fölött; a hiányzó
  /// statisztika számításának idejét a [now] adja.
  factory ArchiveReadServices.over({
    required AppDatabase archive,
    required WebDatabase webDatabase,
    DateTime Function() now = DateTime.now,
    ServerLog log = ignoreServerLog,
  }) {
    final races = RaceRepositoryImpl(archive);
    final results = RaceResultRepository(webDatabase);
    final stats = RaceStatsRepository(webDatabase);
    final manualRaces = ManualRaceRepository(webDatabase);
    final resolveStats = TelemetryStatsResolver(
      calculate: RaceStatsCalculator(
        readTrackSamples: TrackSampleReaderImpl(archive).readWindow,
        readWindSamples: WindSampleReaderImpl(archive).call,
        now: now,
      ),
      log: log,
    );
    return ArchiveReadServices._(
      RaceSummaryService(
        races: races,
        results: results,
        stats: stats,
        manualRaces: manualRaces,
        resolveStats: resolveStats,
        log: log,
      ),
      RaceDetailService(
        races: races,
        readRoundingSamples: RoundingSampleReaderImpl(archive).call,
        results: results,
        stats: stats,
        manualRaces: manualRaces,
        tracks: LegacyTrackRepository(webDatabase),
        resolveStats: resolveStats,
        log: log,
      ),
    );
  }

  /// A napló sorai (`GET /api/races`).
  final RaceSummaryService summaries;

  /// Egy verseny részletezője (`GET /api/races/{id}`).
  final RaceDetailService details;
}
