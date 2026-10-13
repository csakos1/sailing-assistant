import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar_lab/lab_samples_of.dart';

import '../polar/polar_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 10);

  PolarSample sample(
    int second, {
    double? twaDeg = 60,
    double? twsKnots = 10,
    double? stwKnots = 5,
  }) => PolarSample(
    timestamp: start.add(Duration(seconds: second)),
    twaDeg: twaDeg,
    twsMps: twsKnots == null ? null : mps(twsKnots),
    stwMps: stwKnots == null ? null : mps(stwKnots),
  );

  group('labSamplesOf', () {
    test('turns a valid sample into knots and the folded angle', () {
      // ACT
      final labSamples = labSamplesOf(
        [sample(0, twaDeg: -60)],
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: const [],
      );

      // ASSERT
      expect(labSamples, hasLength(1));
      final labSample = labSamples.single;
      expect(labSample.raceId, 'r1');
      expect(labSample.season, 2026);
      expect(labSample.source, PolarSampleSource.telemetry);
      expect(labSample.absTwaDeg, 60);
      expect(labSample.twsKnots, closeTo(10, 1e-9));
      expect(labSample.stwKnots, closeTo(5, 1e-9));
      expect(labSample.seconds, 1);
    });

    test('folds angles past 180 degrees onto the half grid', () {
      final labSamples = labSamplesOf(
        [
          sample(0, twaDeg: 270),
          sample(1, twaDeg: 180),
          sample(2, twaDeg: -190),
        ],
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: const [],
      );

      expect(
        [for (final labSample in labSamples) labSample.absTwaDeg],
        [90, 180, 170],
      );
    });

    test('drops samples with missing or invalid values', () {
      final labSamples = labSamplesOf(
        [
          sample(0, twaDeg: null),
          sample(1, twsKnots: null),
          sample(2, stwKnots: null),
          sample(3, twaDeg: double.nan),
          sample(4, stwKnots: -1),
          sample(5),
        ],
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: const [],
      );

      expect(labSamples, hasLength(1));
    });

    test('drops wind speed spikes like the web statistics', () {
      final labSamples = labSamplesOf(
        [sample(0), sample(1), sample(2, twsKnots: 68), sample(3), sample(4)],
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: const [],
      );

      expect(labSamples, hasLength(4));
      expect(labSamples.every((labSample) => labSample.twsKnots < 11), isTrue);
    });

    test('masks samples after the spike decision', () {
      // ARRANGE: harom 16 kn-os minta a 10 kn-os szelben; a maszk a
      // szelso kettot dobja
      final speeds = <double>[10, 10, 10, 16, 16, 16, 10, 10, 10];
      final samples = [
        for (final (second, knots) in speeds.indexed)
          sample(second, twsKnots: knots),
      ];

      // ACT
      final labSamples = labSamplesOf(
        samples,
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: const [],
        keep: [true, true, true, false, true, false, true, true, true],
      );

      // ASSERT: a teljes soron a kozepso 16 kn nem tuske; ha a maszk elobb
      // szurne, a 10 kn-os szomszedok kozott tuske lenne
      expect(labSamples, hasLength(7));
      final strong = labSamples.where((labSample) => labSample.twsKnots > 15);
      expect(strong, hasLength(1));
    });

    test('rejects a mask of a different length', () {
      expect(
        () => labSamplesOf(
          [sample(0)],
          raceId: 'r1',
          season: 2026,
          source: PolarSampleSource.telemetry,
          corrections: const [],
          keep: [true, true],
        ),
        throwsArgumentError,
      );
    });

    test('applies the water speed correction from its start', () {
      // ARRANGE: a korrekcio a 2. masodperctol el
      final corrections = [
        StwCorrection(from: start.add(const Duration(seconds: 2)), factor: 1.1),
      ];

      // ACT
      final labSamples = labSamplesOf(
        [sample(0), sample(1), sample(2), sample(3)],
        raceId: 'r1',
        season: 2026,
        source: PolarSampleSource.telemetry,
        corrections: corrections,
      );

      // ASSERT
      expect(
        [for (final labSample in labSamples) labSample.stwKnots],
        [
          closeTo(5, 1e-9),
          closeTo(5, 1e-9),
          closeTo(5.5, 1e-9),
          closeTo(5.5, 1e-9),
        ],
      );
    });
  });
}
