import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_sample_collector.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);
  final window = TimeWindow(
    start: start,
    end: start.add(const Duration(hours: 1)),
  );
  final corrections = [
    StwCorrection(from: DateTime.utc(2026, 7, 20), factor: 1.1),
  ];

  PolarRace race(
    String id,
    PolarSampleSource source,
    StatsWindow expectedWindow,
    String day,
  ) => PolarRace(
    id: id,
    name: id,
    source: source,
    expectedWindow: expectedWindow,
    // A `!` biztonsagos: letezo nap.
    day: CalendarDate.tryParse(day)!,
    startInstant: start,
  );

  group('LabSampleCollector', () {
    test('reads each race from its source and window', () async {
      // ARRANGE
      final telemetryCalls = <(String, TimeWindow?)>[];
      final legacyCalls = <(String, TimeWindow?)>[];
      final collector = LabSampleCollector(
        listRaces: () async => [
          race(
            't1',
            PolarSampleSource.telemetry,
            RecordingWindow(window),
            '2026-07-26',
          ),
          race(
            'l1',
            PolarSampleSource.legacyTrack,
            OfficialWindow(window),
            '2024-08-01',
          ),
          race(
            'm1',
            PolarSampleSource.telemetry,
            const ManualEntry(),
            '2026-08-01',
          ),
        ],
        readTelemetrySamples: (raceId, timeWindow) async {
          telemetryCalls.add((raceId, timeWindow));
          return steadySamples(start, 2, stwKnots: 5);
        },
        readLegacySamples: (raceId, timeWindow) async {
          legacyCalls.add((raceId, timeWindow));
          return steadySamples(start, 1, stwKnots: 5, durationSeconds: 10);
        },
        corrections: corrections,
      );

      // ACT
      final samples = await collector();

      // ASSERT: a beirt erteku verseny kimarad
      expect(telemetryCalls, [('t1', window)]);
      expect(legacyCalls, [('l1', window)]);
      expect(samples, hasLength(3));
    });

    test(
      'corrects telemetry only and takes the season from the race day',
      () async {
        final collector = LabSampleCollector(
          listRaces: () async => [
            race(
              't1',
              PolarSampleSource.telemetry,
              RecordingWindow(window),
              '2026-07-26',
            ),
            race(
              'l1',
              PolarSampleSource.legacyTrack,
              OfficialWindow(window),
              '2024-08-01',
            ),
          ],
          readTelemetrySamples: (_, _) async =>
              steadySamples(start, 1, stwKnots: 5),
          readLegacySamples: (_, _) async =>
              steadySamples(start, 1, stwKnots: 5),
          corrections: corrections,
        );

        final samples = await collector();

        // A regi naplo korrekcio nelkul (ADR 0050 D6), akkor is, ha az ideje
        // a korrekcio utan van.
        final telemetry = samples.firstWhere((sample) => sample.raceId == 't1');
        final legacy = samples.firstWhere((sample) => sample.raceId == 'l1');
        expect(telemetry.stwKnots, closeTo(5.5, 1e-9));
        expect(telemetry.season, 2026);
        expect(legacy.stwKnots, closeTo(5, 1e-9));
        expect(legacy.season, 2024);
      },
    );
  });
}
