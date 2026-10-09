import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/track_computed_stats.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

void main() {
  final window = TimeWindow(
    start: DateTime.utc(2023, 7, 6, 8),
    end: DateTime.utc(2023, 7, 6, 12),
  );

  test('gives the stats of a manual race computed from its track', () {
    // ARRANGE
    final stats = RaceStats(window: OfficialWindow(window));
    final summary = RaceSummary(
      id: 'm1',
      name: 'Kekszalag',
      origin: ManualOrigin(CalendarDate.tryParse('2023-07-06')!),
      stats: stats,
    );

    // ACT + ASSERT
    expect(trackComputedStatsOf(summary), stats);
  });

  test('gives nothing for typed values', () {
    final summary = manualSummary('m1', date: '2023-07-06');

    expect(trackComputedStatsOf(summary), isNull);
  });

  test('gives nothing for a telemetry race', () {
    final summary = telemetrySummary('t1', start: DateTime(2026, 7, 26, 11));

    expect(trackComputedStatsOf(summary), isNull);
  });

  test('gives nothing for a new race', () {
    expect(trackComputedStatsOf(null), isNull);
  });
}
