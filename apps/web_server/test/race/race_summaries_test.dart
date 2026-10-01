import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/race/race_summaries.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

void main() {
  final lelleDate = CalendarDate.tryParse('2025-08-23')!;
  final record = ManualRaceRecord(
    id: 'm1',
    input: ManualRaceInput(
      name: 'IX. Lelle Kupa',
      date: lelleDate,
      distanceMeters: 9800,
      maxSpeedMps: 3.55,
      avgWindMps: 1.6,
      maxWindMps: 3.3,
      windPoint: CompassPoint.southEast,
    ),
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10),
  );

  RaceResult resultOf(RaceResultInput content, {String raceId = 'm1'}) =>
      RaceResult(
        raceId: raceId,
        content: content,
        updatedAt: DateTime.utc(2026, 10),
      );

  group('manualSummaryOf', () {
    test('carries the typed values with a manual window', () {
      // ACT
      final summary = manualSummaryOf(record, null);

      // ASSERT
      expect(summary.id, 'm1');
      expect(summary.name, 'IX. Lelle Kupa');
      expect(summary.origin, ManualOrigin(lelleDate));
      expect(summary.stats.window, const ManualEntry());
      expect(summary.stats.track.distanceMeters, 9800);
      expect(summary.stats.track.maxSpeedMps, 3.55);
      expect(summary.stats.windPoint, CompassPoint.southEast);
      expect(summary.result, isNull);
    });

    test('derives the average speed from the official elapsed time', () {
      // ARRANGE: 9800 m in 2 h 0 min 0 s
      final result = resultOf(
        RaceResultInput(
          officialStart: DateTime.utc(2025, 8, 23, 10),
          officialFinish: DateTime.utc(2025, 8, 23, 12),
        ),
      );

      // ACT
      final summary = manualSummaryOf(record, result);

      // ASSERT
      expect(summary.stats.track.avgSpeedMps, closeTo(9800 / 7200, 1e-12));
      expect(summary.result, result);
    });

    test('has no average speed without both official times', () {
      final result = resultOf(
        RaceResultInput(officialStart: DateTime.utc(2025, 8, 23, 10)),
      );

      expect(manualSummaryOf(record, result).stats.track.avgSpeedMps, isNull);
    });

    test('has no average speed for a zero elapsed time', () {
      final instant = DateTime.utc(2025, 8, 23, 10);
      final result = resultOf(
        RaceResultInput(officialStart: instant, officialFinish: instant),
      );

      expect(manualSummaryOf(record, result).stats.track.avgSpeedMps, isNull);
    });
  });

  group('compareNewestFirst', () {
    RaceSummary telemetry(String id, DateTime start, {RaceResult? result}) {
      final recording = TimeWindow(
        start: start,
        end: start.add(const Duration(hours: 3)),
      );
      return telemetrySummaryOf(
        race: Race.create(id: id, name: id, marks: const []),
        recording: recording,
        stats: RaceStats(window: RecordingWindow(recording)),
        result: result,
      );
    }

    test('orders by official start, recording start and manual noon', () {
      // ARRANGE
      final summaries = [
        // A kezi verseny 2025-08-23 delre kerul.
        manualSummaryOf(record, null),
        telemetry('early-morning', DateTime.utc(2025, 8, 23, 6)),
        telemetry(
          'late-official',
          DateTime.utc(2025, 8, 22, 6),
          result: resultOf(
            RaceResultInput(officialStart: DateTime.utc(2025, 8, 23, 15)),
            raceId: 'late-official',
          ),
        ),
      ];

      // ACT
      final sorted = [...summaries]..sort(compareNewestFirst);

      // ASSERT
      expect(sorted.map((summary) => summary.id), [
        'late-official',
        'm1',
        'early-morning',
      ]);
    });

    test('breaks ties by id', () {
      final start = DateTime.utc(2026, 6, 13, 10);
      final sorted = [telemetry('b', start), telemetry('a', start)]
        ..sort(compareNewestFirst);

      expect(sorted.map((summary) => summary.id), ['a', 'b']);
    });
  });
}
