import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_stats_of.dart';

import 'polar_fixtures.dart';

void main() {
  group('polarStatsOf', () {
    test('gives nothing below sixty measured seconds', () {
      expect(polarStatsOf(uniformPerformance(seconds: 59, pct: 95)), isNull);
    });

    test('turns the sums into the table values', () {
      // ACT: 100 mp 95%-on (a 190-es res), 5 m/s szelben
      final stats = polarStatsOf(
        uniformPerformance(seconds: 100, pct: 95, bestFivePct: 120),
      );

      // ASSERT
      expect(
        stats,
        const PolarStats(
          measuredSeconds: 100,
          avgTwsMps: 5,
          avgPct: 95,
          medianPct: 95.25,
          p90Pct: 95.25,
          p99Pct: 95.25,
          bestFivePct: 120,
          shareAtLeast90: 1,
          shareAtLeast100: 0,
        ),
      );
    });
  });

  group('raceAverageOf', () {
    const fast = PolarStats(
      measuredSeconds: 100,
      avgTwsMps: 5,
      avgPct: 95,
      medianPct: 95,
      p90Pct: 100,
      p99Pct: 110,
      bestFivePct: 120,
      shareAtLeast90: 0.8,
      shareAtLeast100: 0.2,
    );
    const slow = PolarStats(
      measuredSeconds: 300,
      avgTwsMps: 3,
      avgPct: 85,
      medianPct: 85,
      p90Pct: 90,
      p99Pct: 100,
      shareAtLeast90: 0.2,
      shareAtLeast100: 0,
    );

    test('averages each column over the races', () {
      expect(
        raceAverageOf(const [fast, slow]),
        const PolarStats(
          measuredSeconds: 400,
          avgPct: 90,
          medianPct: 90,
          p90Pct: 95,
          p99Pct: 105,
          // csak a meglevo ertekek atlaga
          bestFivePct: 120,
          shareAtLeast90: 0.5,
          shareAtLeast100: 0.1,
        ),
      );
    });

    test('gives nothing for no races', () {
      expect(raceAverageOf(const []), isNull);
    });
  });
}
