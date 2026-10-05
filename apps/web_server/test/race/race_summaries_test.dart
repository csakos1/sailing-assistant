import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/race/race_summaries.dart';
import 'package:web_server/src/web_db/cached_race_stats.dart';
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

    group('with stats from an old track', () {
      final start = DateTime.utc(2025, 8, 23, 10);
      final finish = DateTime.utc(2025, 8, 23, 12);
      final official = resultOf(
        RaceResultInput(officialStart: start, officialFinish: finish),
      );
      CachedRaceStats cachedFor(DateTime end) => CachedRaceStats(
        window: OfficialWindow(TimeWindow(start: start, end: end)),
        track: const TrackStats(
          maxSpeedMps: 4.2,
          avgSpeedMps: 2.1,
          distanceMeters: 15100,
        ),
        wind: const WindStats(avgWindMps: 3, directionDeg: 315),
        computedAt: DateTime.utc(2026, 10, 5),
      );

      test('uses a cache row of the current official window', () {
        // ACT
        final summary = manualSummaryOf(
          record,
          official,
          cached: cachedFor(finish),
        );

        // ASSERT
        expect(
          summary.stats.window,
          OfficialWindow(TimeWindow(start: start, end: finish)),
        );
        expect(summary.stats.track.distanceMeters, 15100);
        expect(summary.stats.track.avgSpeedMps, 2.1);
        expect(summary.stats.windPoint, CompassPoint.northWest);
        expect(showsTrackStats(cachedFor(finish), official), isTrue);
      });

      test('falls back to the typed values on a stale row', () {
        // ARRANGE: a sor egy korabbi befutashoz keszult
        final stale = cachedFor(finish.subtract(const Duration(minutes: 5)));

        // ACT
        final summary = manualSummaryOf(record, official, cached: stale);

        // ASSERT
        expect(summary.stats.window, const ManualEntry());
        expect(summary.stats.track.distanceMeters, 9800);
        expect(showsTrackStats(stale, official), isFalse);
      });

      test('falls back to the typed values without official times', () {
        final summary = manualSummaryOf(
          record,
          null,
          cached: cachedFor(finish),
        );

        expect(summary.stats.window, const ManualEntry());
      });
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
