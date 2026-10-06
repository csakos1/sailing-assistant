import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/polar/polar_stats_of.dart';
import 'package:web_server/src/web_db/cached_polar_stats.dart';
import 'package:web_server/src/web_db/polar_stats_repository.dart';

/// A polár-végpontok olvasó szolgáltatása (ADR 0049 D9, D11, D12,
/// Addendum 4 U5, U7, U8).
///
/// Tiszta olvasás: a cache-ből válaszol, nem számol mintákból és nem ír.
/// Az elavult sor értékei megjelennek, a hiányzó sorú verseny sora üres.
class PolarTableService {
  /// Szolgáltatás a [catalog] versenyeire; a frissességet a mostani
  /// [fingerprint] dönti el.
  PolarTableService({
    required PolarRaceCatalog catalog,
    required PolarStatsRepository repository,
    required String fingerprint,
  }) : _catalog = catalog,
       _repository = repository,
       _fingerprint = fingerprint;

  final PolarRaceCatalog _catalog;
  final PolarStatsRepository _repository;
  final String _fingerprint;

  static const _rank = RankPolarPerformance();
  static const _merge = MergePolarPerformance();

  /// A [year] szezon táblázata; ismeretlen évre üres tábla.
  Future<SeasonPolarTable> season(int year) async =>
      _tableOf(year, await _catalog.all(), await _repository.getAll());

  /// Évenként az időre súlyozott sor, a legújabb évvel kezdve.
  Future<List<SeasonPolarSummary>> seasons() async {
    final cached = await _repository.getAll();
    final byYear = <int, List<PolarRace>>{};
    for (final race in await _catalog.all()) {
      byYear.putIfAbsent(race.day.year, () => []).add(race);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final year in years)
        _summaryOf(year, _enoughData(byYear[year] ?? const [], cached)),
    ];
  }

  /// A [raceId] verseny sora a szezonbeli ranggal; `null`, ha nincs
  /// polár-forrása.
  Future<RacePolarDetail?> race(String raceId) async {
    final races = await _catalog.all();
    final race = races.where((other) => other.id == raceId).firstOrNull;
    if (race == null) return null;
    final table = _tableOf(
      race.day.year,
      races,
      await _repository.getAll(),
    );
    final row = table.rows.firstWhere((row) => row.raceId == raceId);
    return RacePolarDetail(row: row, rankedCount: table.rankedCount);
  }

  SeasonPolarTable _tableOf(
    int year,
    List<PolarRace> allRaces,
    Map<String, CachedPolarStats> cached,
  ) {
    final races = [
      for (final race in allRaces)
        if (race.day.year == year) race,
    ]..sort(_byStart);
    // A rang a friss és az elavult sorokból is számol (U8).
    final ranking = _rank({
      for (final race in races)
        if (cached[race.id] case final CachedPolarStats stats)
          race.id: stats.performance,
    });
    final withData = _enoughData(races, cached);
    return SeasonPolarTable(
      year: year,
      rows: [for (final race in races) _rowOf(race, cached[race.id], ranking)],
      raceAverage: raceAverageOf([
        for (final performance in withData)
          if (polarStatsOf(performance) case final PolarStats stats) stats,
      ]),
      timeWeighted: withData.isEmpty ? null : polarStatsOf(_merge(withData)),
      rankedCount: ranking.rankedCount,
    );
  }

  RacePolarRow _rowOf(
    PolarRace race,
    CachedPolarStats? cached,
    PolarRanking ranking,
  ) => RacePolarRow(
    raceId: race.id,
    name: race.name,
    day: race.day,
    elapsed: race.elapsed,
    isApproximate: race.expectedWindow.isApproximate,
    cacheState: polarCacheStateOf(cached, race.expectedWindow, _fingerprint),
    stats: cached == null ? null : polarStatsOf(cached.performance),
    rank: ranking.rankOf(race.id),
  );

  SeasonPolarSummary _summaryOf(int year, List<PolarPerformance> withData) =>
      SeasonPolarSummary(
        year: year,
        raceCount: withData.length,
        timeWeighted: withData.isEmpty ? null : polarStatsOf(_merge(withData)),
      );

  // A legalább 60 mért másodperces versenyek teljesítménye (D8).
  static List<PolarPerformance> _enoughData(
    List<PolarRace> races,
    Map<String, CachedPolarStats> cached,
  ) => [
    for (final race in races)
      if (cached[race.id]?.performance case final PolarPerformance performance
          when performance.hasEnoughData)
        performance,
  ];

  static int _byStart(PolarRace a, PolarRace b) {
    final byTime = a.startInstant.compareTo(b.startInstant);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
