import 'package:race_archive_api/src/json/decode_error.dart';
import 'package:race_archive_api/src/json/json_reader.dart';
import 'package:race_archive_api/src/polar/polar_stats.dart';
import 'package:race_archive_api/src/polar/race_polar_detail.dart';
import 'package:race_archive_api/src/polar/race_polar_row.dart';
import 'package:race_archive_api/src/polar/season_polar_summary.dart';
import 'package:race_archive_api/src/polar/season_polar_table.dart';
import 'package:race_archive_api/src/record/calendar_date_codec.dart';
import 'package:shared/shared.dart';

// A polár-végpontok kodekjei (ADR 0049 D12, Addendum 4 U7). A százalékok
// és az arányok számok, a menetidő ezredmásodperc, a nap `"YYYY-MM-DD"`.

/// A `GET /api/polar/seasons/{year}` válasza.
Map<String, Object?> encodeSeasonPolarTable(SeasonPolarTable table) =>
    <String, Object?>{
      'year': table.year,
      'rows': [for (final row in table.rows) _encodeRow(row)],
      'raceAverage': _encodeOptionalStats(table.raceAverage),
      'timeWeighted': _encodeOptionalStats(table.timeWeighted),
      'rankedCount': table.rankedCount,
    };

/// JSON → [SeasonPolarTable].
Result<SeasonPolarTable, DecodeError> decodeSeasonPolarTable(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return SeasonPolarTable(
        year: reader.integerAtLeast('year', 1),
        rows: reader.list(
          'rows',
          (item, path) => _readRow(JsonReader.at(item, path)),
        ),
        raceAverage: _readOptionalStats(reader, 'raceAverage'),
        timeWeighted: _readOptionalStats(reader, 'timeWeighted'),
        rankedCount: reader.integerAtLeast('rankedCount', 0),
      );
    });

/// A `GET /api/polar/seasons` válasza: `{"seasons": [...]}`.
Map<String, Object?> encodeSeasonPolarSummaries(
  List<SeasonPolarSummary> summaries,
) => <String, Object?>{
  'seasons': [
    for (final summary in summaries)
      <String, Object?>{
        'year': summary.year,
        'raceCount': summary.raceCount,
        'timeWeighted': _encodeOptionalStats(summary.timeWeighted),
      },
  ],
};

/// JSON → a szezonok összesítései.
Result<List<SeasonPolarSummary>, DecodeError> decodeSeasonPolarSummaries(
  Object? json,
) => runDecode(
  () => JsonReader.root(json).list('seasons', (item, path) {
    final reader = JsonReader.at(item, path);
    return SeasonPolarSummary(
      year: reader.integerAtLeast('year', 1),
      raceCount: reader.integerAtLeast('raceCount', 0),
      timeWeighted: _readOptionalStats(reader, 'timeWeighted'),
    );
  }),
);

/// A `GET /api/races/{id}/polar` válasza.
Map<String, Object?> encodeRacePolarDetail(RacePolarDetail detail) =>
    <String, Object?>{
      'row': _encodeRow(detail.row),
      'rankedCount': detail.rankedCount,
    };

/// JSON → [RacePolarDetail].
Result<RacePolarDetail, DecodeError> decodeRacePolarDetail(Object? json) =>
    runDecode(() {
      final reader = JsonReader.root(json);
      return RacePolarDetail(
        row: _readRow(reader.object('row')),
        rankedCount: reader.integerAtLeast('rankedCount', 0),
      );
    });

Map<String, Object?> _encodeRow(RacePolarRow row) => <String, Object?>{
  'raceId': row.raceId,
  'name': row.name,
  'day': row.day.toIso(),
  'elapsedMs': row.elapsed?.inMilliseconds,
  'isApproximate': row.isApproximate,
  'cache': row.cacheState.name,
  'stats': _encodeOptionalStats(row.stats),
  'rank': row.rank,
};

RacePolarRow _readRow(JsonReader reader) {
  final rank = reader.optionalInteger('rank');
  if (rank != null && rank < 1) {
    JsonReader.failAt(reader.childPath('rank'), 'integer >= 1 or null');
  }
  return RacePolarRow(
    raceId: reader.nonEmptyString('raceId'),
    name: reader.string('name'),
    day: readCalendarDate(reader, 'day'),
    elapsed: reader.optionalDurationMillis('elapsedMs'),
    isApproximate: reader.boolean('isApproximate'),
    cacheState: reader.enumByName('cache', PolarCacheState.values),
    stats: _readOptionalStats(reader, 'stats'),
    rank: rank,
  );
}

Map<String, Object?>? _encodeOptionalStats(PolarStats? stats) =>
    stats == null ? null : _encodeStats(stats);

Map<String, Object?> _encodeStats(PolarStats stats) => <String, Object?>{
  'measuredSeconds': stats.measuredSeconds,
  'avgTwsMps': stats.avgTwsMps,
  'avgPct': stats.avgPct,
  'medianPct': stats.medianPct,
  'p90Pct': stats.p90Pct,
  'p99Pct': stats.p99Pct,
  'bestFivePct': stats.bestFivePct,
  'shareAtLeast90': stats.shareAtLeast90,
  'shareAtLeast100': stats.shareAtLeast100,
};

PolarStats? _readOptionalStats(JsonReader parent, String key) {
  final reader = parent.optionalObject(key);
  return reader == null ? null : _readStats(reader);
}

PolarStats _readStats(JsonReader reader) => PolarStats(
  measuredSeconds: reader.integerAtLeast('measuredSeconds', 0),
  avgTwsMps: reader.optionalNumber('avgTwsMps'),
  avgPct: reader.number('avgPct'),
  medianPct: reader.number('medianPct'),
  p90Pct: reader.number('p90Pct'),
  p99Pct: reader.number('p99Pct'),
  bestFivePct: reader.optionalNumber('bestFivePct'),
  shareAtLeast90: _readShare(reader, 'shareAtLeast90'),
  shareAtLeast100: _readShare(reader, 'shareAtLeast100'),
);

double _readShare(JsonReader reader, String key) {
  final share = reader.number(key);
  if (share < 0 || share > 1) {
    JsonReader.failAt(reader.childPath(key), 'number between 0 and 1');
  }
  return share;
}
