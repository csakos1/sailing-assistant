import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'record_fixtures.dart';

void main() {
  group('RaceSummary codec', () {
    test('round-trips a telemetry and a manual race in one list', () {
      // ARRANGE
      final summaries = [telemetrySummary, manualSummary];

      // ACT
      final decoded = unwrap(
        decodeRaceSummaries(overTheWire(encodeRaceSummaries(summaries))),
      );

      // ASSERT
      expect(decoded, summaries);
    });

    test('round-trips an approximate recording window', () {
      // ARRANGE
      final summary = RaceSummary(
        id: 'race-2',
        name: 'Mihalkovics Emlekverseny - 1. nap',
        origin: TelemetryOrigin(recording),
        stats: RaceStats(window: RecordingWindow(recording)),
      );

      // ACT
      final decoded = unwrap(
        decodeRaceSummary(overTheWire(encodeRaceSummary(summary))),
      );

      // ASSERT
      expect(decoded, summary);
      expect(decoded.stats.window.isApproximate, isTrue);
    });

    test('writes the origin and the window as kind-tagged objects', () {
      // ACT
      final telemetry = encodeRaceSummary(telemetrySummary);
      final manual = encodeRaceSummary(manualSummary);

      // ASSERT
      expect(objectAt(telemetry, 'origin'), {
        'kind': 'telemetry',
        'start': recording.start.millisecondsSinceEpoch,
        'end': recording.end.millisecondsSinceEpoch,
      });
      expect(objectAt(manual, 'origin'), {
        'kind': 'manual',
        'date': '2025-08-23',
      });
      expect(objectAt(objectAt(manual, 'stats'), 'window'), {
        'kind': 'manual',
      });
    });

    test('writes the wind direction as a compass point name', () {
      final stats = objectAt(encodeRaceSummary(telemetrySummary), 'stats');

      expect(stats['windPoint'], 'northWest');
    });

    test('rejects a manual window on a telemetry race', () {
      // ARRANGE
      final json = encodeRaceSummary(telemetrySummary);
      objectAt(json, 'stats')['window'] = <String, Object?>{'kind': 'manual'};

      // ACT
      final error = errorOf(decodeRaceSummary(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.stats.window');
    });

    test('rejects a time window on a manual race', () {
      // ARRANGE
      final json = encodeRaceSummary(manualSummary);
      objectAt(json, 'stats')['window'] = <String, Object?>{
        'kind': 'official',
        'start': 0,
        'end': 1,
      };

      // ACT
      final error = errorOf(decodeRaceSummary(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.stats.window');
    });

    test('rejects a window whose end precedes its start', () {
      // ARRANGE
      final json = encodeRaceSummary(telemetrySummary);
      objectAt(json, 'origin')
        ..['start'] = 2000
        ..['end'] = 1000;

      // ACT
      final error = errorOf(decodeRaceSummary(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.origin.end');
    });

    test('rejects an unknown compass point', () {
      final json = encodeRaceSummary(manualSummary);
      objectAt(json, 'stats')['windPoint'] = 'DNy';

      expect(
        errorOf(decodeRaceSummary(overTheWire(json))).path,
        r'$.stats.windPoint',
      );
    });

    test('rejects a date that does not exist', () {
      final json = encodeRaceSummary(manualSummary);
      objectAt(json, 'origin')['date'] = '2025-02-30';

      expect(
        errorOf(decodeRaceSummary(overTheWire(json))).path,
        r'$.origin.date',
      );
    });

    test('rejects an unknown origin kind', () {
      final json = encodeRaceSummary(manualSummary);
      objectAt(json, 'origin')['kind'] = 'excel';

      expect(
        errorOf(decodeRaceSummary(overTheWire(json))).path,
        r'$.origin.kind',
      );
    });

    test('reports the index of a broken list item', () {
      // ARRANGE
      final json = encodeRaceSummaries([telemetrySummary, manualSummary]);
      final second = (json['races']! as List<Object?>)[1]!;
      (second as Map<String, Object?>)['id'] = '';

      // ACT
      final error = errorOf(decodeRaceSummaries(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.races[1].id');
    });
  });

  group('RaceDetail codec', () {
    RaceDetail telemetryDetail() => RaceDetail(
      summary: telemetrySummary,
      telemetry: TelemetryRaceData(
        race: finishedRace(),
        trackPoints: const [
          ArchiveTrackPoint(
            position: Coordinate(latitude: 46.91, longitude: 17.88),
            sogMps: 3.4,
          ),
          ArchiveTrackPoint(
            position: Coordinate(latitude: 46.92, longitude: 17.89),
          ),
        ],
        roundings: [
          RoundingResult(
            fromMark: 'Start',
            toMark: 'Tihany',
            roundedAt: firstRounding,
            predictedTwaDeg: 42.5,
            markTwaDeg: 47,
            forecastBandDeg: 8,
            predictedConfidence: 'high',
            leadTime: const Duration(minutes: 12, seconds: 3),
            lastReliableLeadTime: const Duration(minutes: 9),
            actualSampleCount: 120,
          ),
          RoundingResult(
            fromMark: 'Tihany',
            toMark: 'Fured',
            roundedAt: raceFinish,
          ),
        ],
      ),
    );

    test('round-trips a telemetry race with its track and roundings', () {
      // ARRANGE
      final original = telemetryDetail();

      // ACT
      final decoded = unwrap(
        decodeRaceDetail(overTheWire(encodeRaceDetail(original))),
      );

      // ASSERT
      expect(decoded.summary, original.summary);
      final telemetry = decoded.telemetry;
      expect(telemetry?.race, original.telemetry?.race);
      expect(telemetry?.trackPoints, original.telemetry?.trackPoints);
      // A RoundingResult-nak nincs ==, ezert mezonkent: a kodek minden
      // mezot at kell vigyen.
      final roundings = telemetry?.roundings ?? const <RoundingResult>[];
      expect(roundings, hasLength(2));
      final first = roundings.first;
      expect(first.fromMark, 'Start');
      expect(first.toMark, 'Tihany');
      expect(first.roundedAt, firstRounding);
      expect(first.predictedTwaDeg, 42.5);
      expect(first.markTwaDeg, 47);
      expect(first.forecastBandDeg, 8);
      expect(first.predictedConfidence, 'high');
      expect(first.leadTime, const Duration(minutes: 12, seconds: 3));
      expect(first.lastReliableLeadTime, const Duration(minutes: 9));
      expect(first.actualSampleCount, 120);
      final second = roundings.last;
      expect(second.predictedTwaDeg, isNull);
      expect(second.leadTime, isNull);
      expect(second.actualSampleCount, 0);
    });

    test('encodes track points as compact [lat, lon, sog] arrays', () {
      final json = encodeRaceDetail(telemetryDetail());

      expect(objectAt(json, 'telemetry')['trackPoints'], [
        [46.91, 17.88, 3.4],
        [46.92, 17.89, null],
      ]);
    });

    test('rejects a track point of the wrong shape with its index', () {
      // ARRANGE
      final json = encodeRaceDetail(telemetryDetail());
      (objectAt(json, 'telemetry')['trackPoints']! as List<Object?>)[1] = [
        46.92,
        17.89,
      ];

      // ACT
      final error = errorOf(decodeRaceDetail(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.telemetry.trackPoints[1]');
    });

    test('rejects a negative lead time', () {
      // ARRANGE
      final json = encodeRaceDetail(telemetryDetail());
      final roundings =
          objectAt(json, 'telemetry')['roundings']! as List<Object?>;
      (roundings[0]! as Map<String, Object?>)['leadTimeMs'] = -1;

      // ACT
      final error = errorOf(decodeRaceDetail(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.telemetry.roundings[0].leadTimeMs');
    });

    test('round-trips a manual race without telemetry', () {
      final decoded = unwrap(
        decodeRaceDetail(
          overTheWire(encodeRaceDetail(RaceDetail(summary: manualSummary))),
        ),
      );

      expect(decoded.summary, manualSummary);
      expect(decoded.telemetry, isNull);
    });

    test('rejects a telemetry race without telemetry data', () {
      // ARRANGE
      final json = encodeRaceDetail(telemetryDetail())..['telemetry'] = null;

      // ACT
      final error = errorOf(decodeRaceDetail(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.telemetry');
      expect(error.expected, 'object for a telemetry race');
    });

    test('rejects telemetry data on a manual race', () {
      // ARRANGE
      final json = encodeRaceDetail(RaceDetail(summary: manualSummary))
        ..['telemetry'] = encodeRaceDetail(telemetryDetail())['telemetry'];

      // ACT
      final error = errorOf(decodeRaceDetail(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.telemetry');
      expect(error.expected, 'null for a manual race');
    });
  });

  group('ManualRaceRequest codec', () {
    final request = ManualRaceRequest(
      race: ManualRaceInput(
        name: 'IX. Lelle Kupa',
        date: manualDate,
        distanceMeters: 9800,
        maxSpeedMps: 3.55,
        avgWindMps: 1.6,
        maxWindMps: 3.3,
        windPoint: CompassPoint.southEast,
      ),
      result: const RaceResultInput(
        overallPlace: FinishPlace(3),
        overallFleetSize: 22,
      ),
    );

    test('round-trips the race and the result together', () {
      final decoded = unwrap(
        decodeManualRaceRequest(overTheWire(encodeManualRaceRequest(request))),
      );

      expect(decoded, request);
    });

    test('treats a missing result as an empty result', () {
      // ARRANGE
      final json = encodeManualRaceRequest(request)..remove('result');

      // ACT
      final decoded = unwrap(decodeManualRaceRequest(overTheWire(json)));

      // ASSERT
      expect(decoded.result, const RaceResultInput());
    });

    test('rejects the Hungarian dotted date form', () {
      // ARRANGE
      final json = encodeManualRaceRequest(request);
      objectAt(json, 'race')['date'] = '2025.08.23';

      // ACT
      final error = errorOf(decodeManualRaceRequest(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.race.date');
      expect(error.expected, 'existing date YYYY-MM-DD');
    });

    test('rejects a missing name', () {
      final json = encodeManualRaceRequest(request);
      objectAt(json, 'race').remove('name');

      expect(
        errorOf(decodeManualRaceRequest(overTheWire(json))).path,
        r'$.race.name',
      );
    });
  });
}
