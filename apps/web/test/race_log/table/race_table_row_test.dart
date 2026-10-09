import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/race_log_grouping.dart';
import 'package:foretack_web/race_log/table/race_table_row.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../../support/sample_summaries.dart';

RaceTableRow rowOf(RaceSummary summary) =>
    raceTableRowOf(LogEntry(summary: summary, day: logDayOf(summary)));

void main() {
  group('raceTableRowOf times', () {
    test('takes the recording times as approximate without official ones', () {
      // ARRANGE
      final start = DateTime(2026, 7, 26, 10, 2);
      final summary = telemetrySummary('t1', start: start, hours: 6);

      // ACT
      final row = rowOf(summary);

      // ASSERT
      expect(row.start, (instant: start.toUtc(), isApproximate: true));
      expect(
        row.finish,
        (
          instant: start.add(const Duration(hours: 6)).toUtc(),
          isApproximate: true,
        ),
      );
      expect(row.elapsed, (
        value: const Duration(hours: 6),
        isApproximate: true,
      ));
      expect(row.areStatsApproximate, isTrue);
    });

    test('prefers the official times and their elapsed time', () {
      // ARRANGE
      final officialStart = DateTime(2026, 7, 26, 11);
      final officialFinish = DateTime(2026, 7, 26, 16, 24);
      final summary = telemetrySummary(
        't1',
        start: DateTime(2026, 7, 26, 10),
        result: RaceResultInput(
          officialStart: officialStart,
          officialFinish: officialFinish,
        ),
      );

      // ACT
      final row = rowOf(summary);

      // ASSERT
      expect(row.start, (instant: officialStart, isApproximate: false));
      expect(row.finish, (instant: officialFinish, isApproximate: false));
      expect(row.elapsed, (
        value: const Duration(hours: 5, minutes: 24),
        isApproximate: false,
      ));
    });

    test('leaves the times of a manual race empty without official ones', () {
      final row = rowOf(manualSummary('m1', date: '2024-07-25'));

      expect(row.start, isNull);
      expect(row.finish, isNull);
      expect(row.elapsed, isNull);
      expect(row.isManual, isTrue);
      expect(row.areStatsApproximate, isFalse);
    });

    test('marks a finish on the next local day', () {
      // Given: Kekszalag, rajt 9:00, befutas masnap 8:35.
      final summary = manualSummary(
        'm1',
        date: '2026-07-30',
        result: RaceResultInput(
          officialStart: DateTime(2026, 7, 30, 9),
          officialFinish: DateTime(2026, 7, 31, 8, 35),
        ),
      );

      final row = rowOf(summary);

      expect(row.isFinishNextDay, isTrue);
      expect(row.elapsed?.value, const Duration(hours: 23, minutes: 35));
    });
  });

  group('raceTableRowOf results', () {
    test('pairs every placing with its own fleet size', () {
      final summary = manualSummary(
        'm1',
        date: '2026-07-26',
        result: const RaceResultInput(
          classPlace: FinishPlace(1),
          classFleetSize: 9,
          overallPlace: Dnf(),
          overallFleetSize: 24,
          monohullPlace: FinishPlace(2),
        ),
      );

      final row = rowOf(summary);

      expect(row.classPlace, (placing: const FinishPlace(1), fleetSize: 9));
      expect(row.overallPlace, (placing: const Dnf(), fleetSize: 24));
      expect(row.monohullPlace, (
        placing: const FinishPlace(2),
        fleetSize: null,
      ));
    });

    test('treats a blank prize as no prize', () {
      final summary = manualSummary(
        'm1',
        date: '2026-07-26',
        result: const RaceResultInput(prize: '   '),
      );

      expect(rowOf(summary).prize, isNull);
    });

    test('takes the exact stats of an official window', () {
      // ARRANGE
      final window = TimeWindow(
        start: DateTime(2026, 7, 26, 11),
        end: DateTime(2026, 7, 26, 16),
      );
      final summary = RaceSummary(
        id: 't1',
        name: 'Hivatalos',
        origin: TelemetryOrigin(window),
        stats: RaceStats(
          window: OfficialWindow(window),
          track: const TrackStats(distanceMeters: 22600, maxSpeedMps: 4),
          avgWindMps: 2.5,
          maxWindMps: 5,
          windPoint: CompassPoint.northWest,
        ),
      );

      // ACT
      final row = rowOf(summary);

      // ASSERT
      expect(row.areStatsApproximate, isFalse);
      expect(row.distanceMeters, 22600);
      expect(row.maxSpeedMps, 4);
      expect(row.avgWindMps, 2.5);
      expect(row.maxWindMps, 5);
      expect(row.windPoint, CompassPoint.northWest);
    });
  });
}
