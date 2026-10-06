import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'record_fixtures.dart';

void main() {
  const stats = PolarStats(
    measuredSeconds: 6900,
    avgTwsMps: 5.3,
    avgPct: 87.2,
    medianPct: 89.25,
    p90Pct: 100.75,
    p99Pct: 111.25,
    bestFivePct: 129.7,
    shareAtLeast90: 0.478,
    shareAtLeast100: 0.114,
  );
  final row = RacePolarRow(
    raceId: 'race-1',
    name: 'Horvath Boldizsar emlekverseny',
    // A `!` biztonsagos: letezo nap.
    day: CalendarDate.tryParse('2026-07-26')!,
    elapsed: const Duration(hours: 1, minutes: 56),
    isApproximate: false,
    cacheState: PolarCacheState.fresh,
    stats: stats,
    rank: 1,
  );
  // Regi verseny: nincs legjobb 5 mp, nincs menetido, nincs sora.
  final missingRow = RacePolarRow(
    raceId: 'manual-1',
    name: 'Kekszalag 2024',
    day: CalendarDate.tryParse('2024-07-25')!,
    isApproximate: true,
    cacheState: PolarCacheState.missing,
  );

  group('SeasonPolarTable codec', () {
    test('round-trips rows, summary rows and the ranked count', () {
      // ARRANGE
      final table = SeasonPolarTable(
        year: 2026,
        rows: [row, missingRow],
        raceAverage: const PolarStats(
          measuredSeconds: 6900,
          avgPct: 87.2,
          medianPct: 89.25,
          p90Pct: 100.75,
          p99Pct: 111.25,
          shareAtLeast90: 0.478,
          shareAtLeast100: 0.114,
        ),
        timeWeighted: stats,
        rankedCount: 1,
      );

      // ACT
      final decoded = unwrap(
        decodeSeasonPolarTable(overTheWire(encodeSeasonPolarTable(table))),
      );

      // ASSERT
      expect(decoded, table);
      expect(decoded.isStale, isTrue);
    });

    test('writes the row with day, elapsed time and cache state', () {
      // ACT
      final json = encodeRacePolarDetail(
        RacePolarDetail(row: row, rankedCount: 8),
      );

      // ASSERT
      final rowJson = objectAt(json, 'row');
      expect(rowJson['day'], '2026-07-26');
      expect(rowJson['elapsedMs'], 6960000);
      expect(rowJson['cache'], 'fresh');
      expect(json['rankedCount'], 8);
    });

    test('rejects a share above one', () {
      // ARRANGE
      final json = encodeRacePolarDetail(
        RacePolarDetail(row: row, rankedCount: 8),
      );
      objectAt(objectAt(json, 'row'), 'stats')['shareAtLeast90'] = 1.5;

      // ACT
      final result = decodeRacePolarDetail(overTheWire(json));

      // ASSERT
      expect(
        result,
        const Err<RacePolarDetail, DecodeError>(
          DecodeError(
            path: r'$.row.stats.shareAtLeast90',
            expected: 'number between 0 and 1',
          ),
        ),
      );
    });

    test('rejects a rank below one', () {
      // ARRANGE
      final json = encodeRacePolarDetail(
        RacePolarDetail(row: row, rankedCount: 8),
      );
      objectAt(json, 'row')['rank'] = 0;

      // ACT
      final result = decodeRacePolarDetail(overTheWire(json));

      // ASSERT
      expect(errorOf(result).path, r'$.row.rank');
    });

    test('rejects an unknown cache state', () {
      // ARRANGE
      final json = encodeRacePolarDetail(
        RacePolarDetail(row: row, rankedCount: 8),
      );
      objectAt(json, 'row')['cache'] = 'cold';

      // ACT
      final result = decodeRacePolarDetail(overTheWire(json));

      // ASSERT
      expect(errorOf(result).path, r'$.row.cache');
    });
  });

  group('SeasonPolarSummary codec', () {
    test('round-trips the years', () {
      // ARRANGE
      const summaries = [
        SeasonPolarSummary(year: 2026, raceCount: 8, timeWeighted: stats),
        SeasonPolarSummary(year: 2025, raceCount: 0),
      ];

      // ACT
      final decoded = unwrap(
        decodeSeasonPolarSummaries(
          overTheWire(encodeSeasonPolarSummaries(summaries)),
        ),
      );

      // ASSERT
      expect(decoded, summaries);
    });
  });
}
