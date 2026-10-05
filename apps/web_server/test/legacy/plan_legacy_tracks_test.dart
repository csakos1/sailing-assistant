import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_track_plan_item.dart';
import 'package:web_server/src/legacy/legacy_track_windows.dart';
import 'package:web_server/src/legacy/plan_legacy_tracks.dart';

import 'legacy_track_fixtures.dart';

void main() {
  final start = DateTime.utc(2023, 7, 1, 10);
  // 100 mp-es ablak: 10 minta adna 100 %-ot.
  final finish = start.add(const Duration(seconds: 100));

  group('legacyTrackWindowsOf', () {
    test('gives a window only to a race with both official times', () {
      // ARRANGE
      final races = [
        legacyManualRecord('m1'),
        legacyManualRecord('m2'),
        legacyManualRecord('m3'),
      ];
      final results = {
        'm1': legacyResult('m1', start, finish),
        // A befutas a rajt elott: ervenytelen ablak.
        'm2': legacyResult('m2', finish, start),
      };

      // ACT
      final windows = legacyTrackWindowsOf(
        manualRaces: races,
        results: results,
      );

      // ASSERT
      expect(windows, [
        (raceId: 'm1', window: TimeWindow(start: start, end: finish)),
      ]);
    });
  });

  group('planLegacyTracks', () {
    test('plans a track with its coverage and distance', () {
      // ARRANGE: 9 samples (0..8), 8 steps of 111.19 m
      final race = legacyManualRecord('m1', distanceMeters: 1000);

      // ACT
      final plan = planLegacyTracks(
        manualRaces: [race],
        results: {'m1': legacyResult('m1', start, finish)},
        tracks: {
          'm1': [
            for (var step = 0; step < 9; step++) legacyStepSample(start, step),
          ],
        },
      );

      // ASSERT
      final item = plan.single as PlannedLegacyTrack;
      expect(item.window, TimeWindow(start: start, end: finish));
      expect(item.samples, hasLength(9));
      expect(item.coverage, closeTo(0.9, 1e-12));
      expect(item.distanceMeters, closeTo(8 * 111.19, 0.1));
    });

    test('caps the coverage at one', () {
      // ARRANGE: 12 samples in a 100 s window
      final plan = planLegacyTracks(
        manualRaces: [legacyManualRecord('m1')],
        results: {'m1': legacyResult('m1', start, finish)},
        tracks: {
          'm1': [
            for (var step = 0; step < 12; step++) legacyStepSample(start, step),
          ],
        },
      );

      // ASSERT
      expect((plan.single as PlannedLegacyTrack).coverage, 1);
    });

    test('gives no track without an official window', () {
      final race = legacyManualRecord('m1');

      final plan = planLegacyTracks(
        manualRaces: [race],
        results: const {},
        tracks: {
          'm1': [legacyStepSample(start, 0), legacyStepSample(start, 1)],
        },
      );

      expect(plan, [LegacyTrackWithoutWindow(race)]);
    });

    test('gives no track with fewer than two positions', () {
      // ARRANGE: three samples, only one with a position
      final race = legacyManualRecord('m1');

      // ACT
      final plan = planLegacyTracks(
        manualRaces: [race],
        results: {'m1': legacyResult('m1', start, finish)},
        tracks: {
          'm1': [
            legacyStepSample(start, 0),
            legacyStepSample(start, 1, hasPosition: false),
            legacyStepSample(start, 2, hasPosition: false),
          ],
        },
      );

      // ASSERT
      expect(plan, [
        LegacyTrackTooShort(
          race,
          window: TimeWindow(start: start, end: finish),
          sampleCount: 3,
          positionCount: 1,
        ),
      ]);
    });

    test('gives no track when the CSV has nothing in the window', () {
      final race = legacyManualRecord('m1');

      final plan = planLegacyTracks(
        manualRaces: [race],
        results: {'m1': legacyResult('m1', start, finish)},
        tracks: const {},
      );

      expect(plan.single, isA<LegacyTrackTooShort>());
    });

    test('orders the races by day, then by name', () {
      // ARRANGE
      final races = [
        legacyManualRecord('a', name: 'Kekszalag', date: '2023-07-01'),
        legacyManualRecord('b', name: 'Alkotmany', date: '2023-08-20'),
        legacyManualRecord('c', name: 'Evadnyito', date: '2023-07-01'),
      ];

      // ACT
      final plan = planLegacyTracks(
        manualRaces: races,
        results: const {},
        tracks: const {},
      );

      // ASSERT
      expect([for (final item in plan) item.race.id], ['c', 'a', 'b']);
    });
  });
}
