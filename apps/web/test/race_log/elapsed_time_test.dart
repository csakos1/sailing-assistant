import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/elapsed_time.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../support/sample_summaries.dart';

void main() {
  final officialStart = DateTime.utc(2026, 7, 26, 9);

  group('elapsedTimeOf', () {
    test('takes the positive official elapsed time as exact', () {
      // ARRANGE
      final summary = telemetrySummary(
        't1',
        start: DateTime(2026, 7, 26, 10),
        hours: 6,
        result: RaceResultInput(
          officialStart: officialStart,
          officialFinish: officialStart.add(const Duration(hours: 3)),
        ),
      );

      // ACT
      final elapsed = elapsedTimeOf(summary);

      // ASSERT
      expect(elapsed, (value: const Duration(hours: 3), isApproximate: false));
    });

    test('falls back to the recording without official times', () {
      // ARRANGE
      final summary = telemetrySummary(
        't1',
        start: DateTime(2026, 7, 26, 10),
        hours: 6,
      );

      // ACT
      final elapsed = elapsedTimeOf(summary);

      // ASSERT
      expect(elapsed, (value: const Duration(hours: 6), isApproximate: true));
    });

    test('ignores a zero official elapsed time', () {
      // ARRANGE: a rajt es a befutas ugyanaz a pillanat
      final summary = telemetrySummary(
        't1',
        start: DateTime(2026, 7, 26, 10),
        hours: 2,
        result: RaceResultInput(
          officialStart: officialStart,
          officialFinish: officialStart,
        ),
      );

      // ACT
      final elapsed = elapsedTimeOf(summary);

      // ASSERT
      expect(elapsed, (value: const Duration(hours: 2), isApproximate: true));
    });

    test('gives the official time of a manual race', () {
      // ARRANGE
      final summary = manualSummary(
        'm1',
        date: '2024-07-25',
        result: RaceResultInput(
          officialStart: officialStart,
          officialFinish: officialStart.add(const Duration(minutes: 90)),
        ),
      );

      // ACT
      final elapsed = elapsedTimeOf(summary);

      // ASSERT
      expect(elapsed, (
        value: const Duration(minutes: 90),
        isApproximate: false,
      ));
    });

    test('gives nothing for a manual race without official times', () {
      // ARRANGE
      final summary = manualSummary('m1', date: '2024-07-25');

      // ACT + ASSERT
      expect(elapsedTimeOf(summary), isNull);
    });
  });
}
