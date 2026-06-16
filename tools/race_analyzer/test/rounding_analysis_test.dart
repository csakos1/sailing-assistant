import 'dart:io';

import 'package:race_analyzer/race_analyzer.dart';
import 'package:test/test.dart';

void main() {
  final base = DateTime.utc(2026, 6, 6, 11);

  // Szintetikus korozes-folyam: `approachTicks` tick 'A'-n a megadott
  // predikcioval/konfidenciaval, majd `legTicks` tick 'B'-n a megadott
  // tenyleges TWA-val. A korozes (A->B) az approachTicks indexnel van.
  List<AnalyzerSnapshot> scenario({
    int approachTicks = 10,
    int legTicks = 31,
    double predictedTwa = -120,
    double? band = 5,
    String confidence = 'high',
    double actualTwa = -117,
  }) {
    return <AnalyzerSnapshot>[
      for (var i = 0; i < approachTicks; i++)
        AnalyzerSnapshot(
          tickTime: base.add(Duration(seconds: i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'A',
          predictedTwaAtMarkDeg: predictedTwa,
          shiftConfidence: confidence,
          forecastBandDeg: band,
          currentTwaDeg: predictedTwa,
        ),
      for (var i = 0; i < legTicks; i++)
        AnalyzerSnapshot(
          tickTime: base.add(Duration(seconds: approachTicks + i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'B',
          currentTwaDeg: actualTwa,
        ),
    ];
  }

  group('analyzeRoundings — egy korozes', () {
    test('predikalt vs tenyleges, savon belul, lead-time', () {
      // ARRANGE
      final snaps = scenario();

      // ACT
      final results = analyzeRoundings(snaps);

      // ASSERT
      expect(results, hasLength(1));
      final result = results.single;
      expect(result.fromMark, 'A');
      expect(result.toMark, 'B');
      expect(result.predictedTwaDeg, -120);
      expect(result.predictedConfidence, 'high');
      expect(result.forecastBandDeg, 5);
      expect(result.actualSampleCount, 20); // [skip 10s, +20s) -> 20 tick
      expect(result.actualTwaDeg, closeTo(-117, 1e-6));
      expect(result.deltaDeg, closeTo(3, 1e-6));
      expect(result.isWithinBand, isTrue);
      // 10 megszakitatlan 'high' tick a korozesig.
      expect(result.leadTime, const Duration(seconds: 10));
    });

    test('a savon kivuli delta isWithinBand=false', () {
      // ARRANGE — szuk sav, nagy elteres.
      final snaps = scenario(predictedTwa: -100);

      // ACT
      final result = analyzeRoundings(snaps).single;

      // ASSERT
      expect(result.deltaDeg, closeTo(-17, 1e-6));
      expect(result.isWithinBand, isFalse);
    });

    test('predikcio nelkul a delta es a sav-itelet null', () {
      // ARRANGE — minden tick 'A'/'B', de a predikcio vegig null.
      final snaps = <AnalyzerSnapshot>[
        for (var i = 0; i < 10; i++)
          AnalyzerSnapshot(
            tickTime: base.add(Duration(seconds: i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            currentTwaDeg: -120,
          ),
        for (var i = 0; i < 31; i++)
          AnalyzerSnapshot(
            tickTime: base.add(Duration(seconds: 10 + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'B',
            currentTwaDeg: -117,
          ),
      ];

      // ACT
      final result = analyzeRoundings(snaps).single;

      // ASSERT
      expect(result.predictedTwaDeg, isNull);
      expect(result.deltaDeg, isNull);
      expect(result.isWithinBand, isNull);
      expect(result.actualTwaDeg, closeTo(-117, 1e-6)); // a tenyleges megvan
    });

    test('lead-time null, ha a korozeskor nem volt megbizhato', () {
      // ARRANGE — az approach-tickek vegig low konfidenciaval.
      final snaps = scenario(confidence: 'low');

      // ACT
      final result = analyzeRoundings(snaps).single;

      // ASSERT
      expect(result.leadTime, isNull);
    });
  });

  group('wrapTo180', () {
    test('a [-180,180) tartomanyba normalizal', () {
      expect(wrapTo180(0), 0);
      expect(wrapTo180(190), closeTo(-170, 1e-9));
      expect(wrapTo180(-190), closeTo(170, 1e-9));
      expect(wrapTo180(180), closeTo(-180, 1e-9));
      expect(wrapTo180(359), closeTo(-1, 1e-9));
    });
  });

  group('fixtura (2026-06-06 bootstrap)', () {
    test('a valodi snapshot_logs ket korozest ad, lancba fuzve', () {
      final fixture = File('test/fixtures/snapshot_logs_2026_06_06.jsonl');
      if (!fixture.existsSync()) {
        markTestSkipped('nincs fixtura — futtasd a bootstrapot (ADR 0025 D5)');
        return;
      }

      // ACT
      final snaps = readSnapshotsFromJsonl(fixture.path);
      final results = analyzeRoundings(snaps);

      // ASSERT — szerkezet (a konkret ertekeket a CLI-report mutatja).
      expect(snaps, isNotEmpty);
      expect(results, hasLength(2), reason: 'VK->BS es BS->VK2');
      expect(results[0].toMark, results[1].fromMark); // a kozepso boja
      expect(results[0].roundedAt.isBefore(results[1].roundedAt), isTrue);
    });
  });
}
