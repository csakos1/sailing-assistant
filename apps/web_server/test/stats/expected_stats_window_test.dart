import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/stats/expected_stats_window.dart';

import '../support/archive_fixture.dart';

void main() {
  final recording = TimeWindow(
    start: DateTime.utc(2026, 7, 26, 8),
    end: DateTime.utc(2026, 7, 26, 15),
  );
  final start = DateTime.utc(2026, 7, 26, 9);
  final finish = DateTime.utc(2026, 7, 26, 14, 24);

  group('expectedStatsWindow', () {
    test('uses the official window when both times are set', () {
      final window = expectedStatsWindow(
        recording: recording,
        result: RaceResultInput(officialStart: start, officialFinish: finish),
      );

      expect(window, OfficialWindow(TimeWindow(start: start, end: finish)));
    });

    test('falls back to the recording without a result', () {
      expect(
        expectedStatsWindow(recording: recording),
        RecordingWindow(recording),
      );
    });

    test('falls back to the recording with only one official time', () {
      final window = expectedStatsWindow(
        recording: recording,
        result: RaceResultInput(officialStart: start),
      );

      expect(window, RecordingWindow(recording));
    });

    test('falls back to the recording when the finish is not after the '
        'start', () {
      final window = expectedStatsWindow(
        recording: recording,
        result: RaceResultInput(officialStart: start, officialFinish: start),
      );

      expect(window, RecordingWindow(recording));
    });
  });

  group('recordingWindowOf', () {
    test('spans from the start to the finish of a finished race', () {
      // ARRANGE: the fixture rounds its only mark two hours after the start
      final race = finishedArchiveRace('r1');

      // ACT
      final window = recordingWindowOf(race);

      // ASSERT
      expect(
        window,
        TimeWindow(
          start: archiveStart,
          end: archiveStart.add(const Duration(hours: 2)),
        ),
      );
    });

    test('is null for a race that never started', () {
      final race = Race.create(id: 'r2', name: 'Teszt', marks: const []);

      expect(recordingWindowOf(race), isNull);
    });
  });

  group('officialWindowOf', () {
    test('spans the official start and finish', () {
      final window = officialWindowOf(
        RaceResultInput(officialStart: start, officialFinish: finish),
      );

      expect(window, TimeWindow(start: start, end: finish));
    });

    test('is null without a result', () {
      expect(officialWindowOf(null), isNull);
    });

    test('is null when the finish is missing', () {
      expect(officialWindowOf(RaceResultInput(officialStart: start)), isNull);
    });

    test('is null when the finish equals the start', () {
      final window = officialWindowOf(
        RaceResultInput(officialStart: start, officialFinish: start),
      );

      expect(window, isNull);
    });
  });
}
