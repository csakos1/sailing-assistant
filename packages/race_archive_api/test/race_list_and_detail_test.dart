import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

T unwrap<T>(Result<T, DecodeError> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError('Ok-t vartunk: $error'),
};

DecodeError errorOf<T>(Result<T, DecodeError> result) => switch (result) {
  Ok() => throw StateError('Err-t vartunk, Ok jott'),
  Err(:final error) => error,
};

Object? overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json));

final RaceAnnotation annotation = RaceAnnotation(
  raceId: 'race-1',
  content: const RaceAnnotationInput(
    overallPlace: 3,
    overallFleetSize: 24,
    summary: 'Eros delnyugati, a Tihanyi-szorosban lyukba futottunk.',
  ),
  updatedAt: DateTime.utc(2026, 9, 30, 18),
);

const TrackStats stats = TrackStats(
  maxSpeedMps: 6.2,
  avgSpeedMps: 3.1,
  distanceMeters: 41250,
);

void main() {
  group('race list', () {
    test('round-trips items with and without annotation', () {
      // ARRANGE
      final items = [
        RaceListItem(
          race: finishedRace(),
          trackStats: stats,
          annotation: annotation,
        ),
        RaceListItem(
          race: finishedRace(id: 'race-2', name: 'Szent Mihaly-kupa'),
          trackStats: const TrackStats(),
        ),
      ];

      // ACT
      final decoded = unwrap(
        decodeRaceList(overTheWire(encodeRaceList(items))),
      );

      // ASSERT
      expect(decoded, items);
    });

    test('reports the index of a broken item', () {
      // ARRANGE
      final json = encodeRaceList([
        RaceListItem(race: finishedRace(), trackStats: stats),
        RaceListItem(
          race: finishedRace(id: 'race-2'),
          trackStats: stats,
        ),
      ]);
      final races = json['races']! as List<Object?>;
      final second = races[1]! as Map<String, Object?>;
      (second['trackStats']! as Map<String, Object?>)['maxSpeedMps'] = 'gyors';

      // ACT
      final error = errorOf(decodeRaceList(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.races[1].trackStats.maxSpeedMps');
    });
  });

  group('race detail', () {
    RaceDetail detail({RaceAnnotation? annotation}) => RaceDetail(
      race: finishedRace(),
      trackStats: stats,
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
      annotation: annotation,
    );

    test('round-trips every field', () {
      // ARRANGE
      final original = detail(annotation: annotation);

      // ACT
      final decoded = unwrap(
        decodeRaceDetail(overTheWire(encodeRaceDetail(original))),
      );

      // ASSERT
      expect(decoded.race, original.race);
      expect(decoded.trackStats, original.trackStats);
      expect(decoded.trackPoints, original.trackPoints);
      expect(decoded.annotation, original.annotation);
      // A RoundingResult-nak nincs ==, ezert mezonkent: a kodek minden
      // mezot at kell vigyen.
      expect(decoded.roundings, hasLength(2));
      final first = decoded.roundings.first;
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
      final second = decoded.roundings.last;
      expect(second.predictedTwaDeg, isNull);
      expect(second.leadTime, isNull);
      expect(second.actualSampleCount, 0);
    });

    test('encodes track points as compact [lat, lon, sog] arrays', () {
      final json = encodeRaceDetail(detail());

      expect(json['trackPoints'], [
        [46.91, 17.88, 3.4],
        [46.92, 17.89, null],
      ]);
    });

    test('rejects a track point of the wrong shape with its index', () {
      // ARRANGE
      final json = encodeRaceDetail(detail());
      (json['trackPoints']! as List<Object?>)[1] = [46.92, 17.89];

      // ACT
      final error = errorOf(decodeRaceDetail(overTheWire(json)));

      // ASSERT
      expect(error.path, r'$.trackPoints[1]');
    });

    test('rejects a negative lead time', () {
      final json = encodeRaceDetail(detail());
      final roundings = json['roundings']! as List<Object?>;
      (roundings[0]! as Map<String, Object?>)['leadTimeMs'] = -1;

      expect(
        errorOf(decodeRaceDetail(overTheWire(json))).path,
        r'$.roundings[0].leadTimeMs',
      );
    });
  });

  group('annotation', () {
    test('round-trips the stored annotation', () {
      final decoded = unwrap(
        decodeRaceAnnotation(overTheWire(encodeRaceAnnotation(annotation))),
      );

      expect(decoded, annotation);
    });

    test('decodes an input with only some fields present', () {
      final decoded = unwrap(
        decodeRaceAnnotationInput(<String, Object?>{'classPlace': 2}),
      );

      expect(decoded, const RaceAnnotationInput(classPlace: 2));
    });

    test('accepts an integral double as integer (JS numbers on the web)', () {
      final decoded = unwrap(
        decodeRaceAnnotationInput(<String, Object?>{'overallPlace': 3.0}),
      );

      expect(decoded.overallPlace, 3);
    });

    test('rejects a fractional place as a shape error, not a violation', () {
      final error = errorOf(
        decodeRaceAnnotationInput(<String, Object?>{'overallPlace': 2.5}),
      );

      expect(error.path, r'$.overallPlace');
    });
  });
}
