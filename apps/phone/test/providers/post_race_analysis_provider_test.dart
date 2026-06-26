import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/post_race_analysis_provider.dart';
import 'package:phone/providers/rounding_sample_reader_provider.dart';

void main() {
  final base = DateTime.utc(2026, 6, 6, 11);

  // Egy A->B megkerulest ado minta-folyam: 10 tick 'A'-n high predikcioval,
  // majd 31 tick 'B'-n a tenyleges TWA-val (a COG = leg-irany, a kapu nyit).
  List<RoundingSample> scenario() {
    return <RoundingSample>[
      for (var i = 0; i < 10; i++)
        RoundingSample(
          tickTime: base.add(Duration(seconds: i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'A',
          predictedTwaAtMarkDeg: -120,
          shiftConfidence: 'high',
          forecastBandDeg: 5,
          currentTwaDeg: -120,
        ),
      for (var i = 0; i < 31; i++)
        RoundingSample(
          tickTime: base.add(Duration(seconds: 10 + i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'B',
          currentTwaDeg: -117,
          bearingToMarkDeg: 90,
          cogDeg: 90,
        ),
    ];
  }

  ProviderContainer makeContainer(RoundingSampleReader reader) {
    final container = ProviderContainer(
      overrides: [
        roundingSampleReaderProvider.overrideWithValue(reader),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('postRaceAnalysisProvider', () {
    test('a reader mintait elemzi es osszegzi', () async {
      // ARRANGE
      final container = makeContainer((_) async => scenario());

      // ACT
      final analysis = await container.read(
        postRaceAnalysisProvider('race-1').future,
      );

      // ASSERT — egy A->B megkerules, savon belul (delta 3, sav 5), lead 10 s.
      expect(analysis.isEmpty, isFalse);
      expect(analysis.roundings, hasLength(1));
      expect(analysis.roundings.single.toMark, 'B');
      expect(analysis.summary.bandTotal, 1);
      expect(analysis.summary.bandHits, 1);
      expect(analysis.summary.avgAbsDeltaDeg, closeTo(3, 1e-6));
      expect(analysis.summary.avgLeadTime, const Duration(seconds: 10));
    });

    test('ures reader -> ures elemzes', () async {
      // ARRANGE
      final container = makeContainer((_) async => const <RoundingSample>[]);

      // ACT
      final analysis = await container.read(
        postRaceAnalysisProvider('race-1').future,
      );

      // ASSERT
      expect(analysis.isEmpty, isTrue);
      expect(analysis.roundings, isEmpty);
      expect(analysis.summary.bandTotal, 0);
      expect(analysis.summary.bandHits, 0);
      expect(analysis.summary.avgAbsDeltaDeg, isNull);
    });

    test('a track-pontokat es -statokat is szamolja', () async {
      // ARRANGE — ket pozicios minta (VK -> BS), sebesseggel.
      final samples = <RoundingSample>[
        RoundingSample(
          tickTime: base,
          raceStatus: 'active',
          twdQuality: 'live',
          sogMps: 2,
          latDeg: 46.946554,
          lonDeg: 18.012115,
        ),
        RoundingSample(
          tickTime: base.add(const Duration(seconds: 1)),
          raceStatus: 'active',
          twdQuality: 'live',
          sogMps: 4,
          latDeg: 46.931763,
          lonDeg: 18.045607,
        ),
      ];
      final container = makeContainer((_) async => samples);

      // ACT
      final analysis = await container.read(
        postRaceAnalysisProvider('race-1').future,
      );

      // ASSERT — ket track-pont, max/atlag SOG, ~3028 m uthossz.
      expect(analysis.trackPoints, hasLength(2));
      expect(analysis.trackStats.maxSpeedMps, 4);
      expect(analysis.trackStats.avgSpeedMps, 3);
      expect(analysis.trackStats.distanceMeters, closeTo(3028.29, 1));
    });
  });
}
