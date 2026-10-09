import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/server_log.dart';
import 'package:web_server/src/stats/race_stats_calculator.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';

/// A `GET`-ek statisztikája: a cache-ből, ha érvényes, különben memóriában
/// számolva (ADR 0048 D4 + Addendum 3 I4).
///
/// **Nem ír**: a `GET` mellékhatás nélküli. Egy hiányzó vagy elavult sor
/// azt jelenti, hogy az import vagy a mentés frissítése elbukott; ezt
/// naplózza, a következő import pótolja.
class TelemetryStatsResolver {
  /// Feloldó a [calculate] számolóval.
  TelemetryStatsResolver({
    required RaceStatsCalculator calculate,
    ServerLog log = ignoreServerLog,
  }) : _calculate = calculate,
       _log = log;

  final RaceStatsCalculator _calculate;
  final ServerLog _log;

  /// A [raceId] verseny statisztikája a várt [expected] ablakból; a
  /// [cached] a tárolt sor, ha van.
  Future<RaceStats> call(
    String raceId,
    StatsWindow expected,
    CachedRaceStats? cached,
  ) async {
    if (cached != null && cached.window == expected) {
      return cached.toRaceStats();
    }
    _log('hiányzó vagy elavult race_stats sor ($raceId): memóriában számolva');
    return (await _calculate(raceId, expected)).toRaceStats();
  }
}
