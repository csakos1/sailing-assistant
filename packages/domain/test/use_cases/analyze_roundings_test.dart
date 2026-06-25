import 'package:domain/domain.dart';
import 'package:domain/src/_internal/wrap_angle.dart';
import 'package:test/test.dart';

void main() {
  const analyze = AnalyzeRoundings();
  final base = DateTime.utc(2026, 6, 6, 11);

  // Szintetikus korozes-folyam: `approachTicks` tick 'A'-n a megadott
  // predikcioval/konfidenciaval, majd `legTicks` tick 'B'-n a megadott
  // tenyleges TWA-val. A 'B'-tickek a leg-iranyt (bearingToMark) es a
  // COG-ot is hordozzak, hogy a COG-kapu (ADR 0026) nyithasson; alapbol
  // a COG = a leg-irany (in-tolerance). A korozes (A->B) az approachTicks
  // indexnel van.
  List<RoundingSample> scenario({
    int approachTicks = 10,
    int legTicks = 31,
    double predictedTwa = -120,
    double? band = 5,
    String confidence = 'high',
    double actualTwa = -117,
    double legBearingDeg = 90,
    double legCogDeg = 90,
  }) {
    return <RoundingSample>[
      for (var i = 0; i < approachTicks; i++)
        RoundingSample(
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
        RoundingSample(
          tickTime: base.add(Duration(seconds: approachTicks + i)),
          raceStatus: 'active',
          twdQuality: 'live',
          markName: 'B',
          currentTwaDeg: actualTwa,
          bearingToMarkDeg: legBearingDeg,
          cogDeg: legCogDeg,
        ),
    ];
  }

  group('analyzeRoundings — egy korozes', () {
    test('predikalt vs tenyleges, savon belul, lead-time', () {
      // ARRANGE
      final snaps = scenario();

      // ACT
      final results = analyze(snaps);

      // ASSERT
      expect(results, hasLength(1));
      final result = results.single;
      expect(result.fromMark, 'A');
      expect(result.toMark, 'B');
      expect(result.predictedTwaDeg, -120);
      expect(result.predictedConfidence, 'high');
      expect(result.forecastBandDeg, 5);
      // A kapu a floor-nal (base+20s) nyilik, ablak [+20s, +40s) -> 20 tick.
      expect(result.actualSampleCount, 20);
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
      final result = analyze(snaps).single;

      // ASSERT
      expect(result.deltaDeg, closeTo(-17, 1e-6));
      expect(result.isWithinBand, isFalse);
    });

    test('predikcio nelkul a delta es a sav-itelet null', () {
      // ARRANGE — minden tick 'A'/'B', de a predikcio vegig null. A 'B'
      // tickek COG-ja a leg-iranyon (a kapu nyit, a tenyleges merheto).
      final snaps = <RoundingSample>[
        for (var i = 0; i < 10; i++)
          RoundingSample(
            tickTime: base.add(Duration(seconds: i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
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

      // ACT
      final result = analyze(snaps).single;

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
      final result = analyze(snaps).single;

      // ASSERT
      expect(result.leadTime, isNull);
    });
  });

  group('COG-kapuzott beallas (ADR 0026)', () {
    // Egy korozes 'high' approach-csal; a 'B' legen elobb off-leg COG
    // (atmenet), majd a megadott pillanattol in-leg COG (beallt).
    List<RoundingSample> lateSettle({
      required int offTicks,
      required int onTicks,
      double offCog = 270,
      double onCog = 90,
      double legBearing = 90,
      double transientTwa = -40,
      double settledTwa = 118,
      List<int> flukeOffsets = const [],
    }) {
      final snaps = <RoundingSample>[
        for (var i = 0; i < 10; i++)
          RoundingSample(
            tickTime: base.add(Duration(seconds: i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            predictedTwaAtMarkDeg: 120,
            shiftConfidence: 'high',
            forecastBandDeg: 5,
            currentTwaDeg: 120,
          ),
      ];
      for (var i = 0; i < offTicks; i++) {
        final cog = flukeOffsets.contains(i) ? onCog : offCog;
        snaps.add(
          RoundingSample(
            tickTime: base.add(Duration(seconds: 10 + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'B',
            currentTwaDeg: transientTwa,
            bearingToMarkDeg: legBearing,
            cogDeg: cog,
          ),
        );
      }
      for (var i = 0; i < onTicks; i++) {
        snaps.add(
          RoundingSample(
            tickTime: base.add(Duration(seconds: 10 + offTicks + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'B',
            currentTwaDeg: settledTwa,
            bearingToMarkDeg: legBearing,
            cogDeg: onCog,
          ),
        );
      }
      return snaps;
    }

    test('a kapu csak a COG-konvergencianal nyilik (nem az atmeneten)', () {
      // ARRANGE — 60 tick off-leg (COG 270), majd 30 tick on-leg (COG 90).
      final snaps = lateSettle(offTicks: 60, onTicks: 30);

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a beallt 118-at meri, nem az atmeneti -40-et.
      expect(result.actualTwaDeg, closeTo(118, 1e-6));
      expect(result.predictedTwaDeg, 120);
      expect(result.deltaDeg, closeTo(-2, 1e-6));
    });

    test('sosem all be: a COG vegig off-leg -> n/a', () {
      // ARRANGE — 60 tick off-leg, soha nincs on-leg (pl. kereszt-leg).
      final snaps = lateSettle(offTicks: 60, onTicks: 0);

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — nincs beallt ablak, a tenyleges n/a; a predikalt megvan.
      expect(result.actualTwaDeg, isNull);
      expect(result.actualSampleCount, 0);
      expect(result.deltaDeg, isNull);
      expect(result.predictedTwaDeg, 120);
    });

    test('debounce: egyetlen fluke in-tol tick nem nyitja a kaput', () {
      // ARRANGE — az atmenet 20. tickjenel (base+30s) egyetlen fluke
      // in-tol COG; a tartos beallas csak utana. A 3 s debounce eldobja.
      final snaps = lateSettle(
        offTicks: 25,
        onTicks: 30,
        flukeOffsets: const [20],
      );

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a fluke (atmeneti -40) nem nyit; a beallt 118 jon.
      expect(result.actualTwaDeg, closeTo(118, 1e-6));
    });

    test('cog-tolerance 360: a kapu a floor-nal nyilik (regi fix-ido)', () {
      // ARRANGE — a 'B' legen a COG vegig off-leg (270).
      final snaps = scenario(legCogDeg: 270);

      // ACT — 20-as tol: a kapu sosem nyilik; 360-as tol: a floor-nal.
      final tight = analyze(snaps).single;
      final loose = analyze(
        snaps,
        params: const AnalysisParams(cogToleranceDeg: 360),
      ).single;

      // ASSERT
      expect(tight.actualTwaDeg, isNull);
      expect(loose.actualSampleCount, 20);
      expect(loose.actualTwaDeg, closeTo(-117, 1e-6));
    });
  });

  group('lead-time a freeze folott (ADR 0027)', () {
    // 'A' approach: `highTicks` high (nem-null) + opcionalis 1 genuine-low
    // (nem-null, low) + `freezeTicks` freeze (null predikcio, low), majd a
    // 'B' leg. A markName-valtas (= korozes) az elso 'B'-nel van.
    List<RoundingSample> withFreeze({
      int highTicks = 10,
      int freezeTicks = 5,
      bool genuineLowBeforeFreeze = false,
    }) {
      final snaps = <RoundingSample>[
        for (var i = 0; i < highTicks; i++)
          RoundingSample(
            tickTime: base.add(Duration(seconds: i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            predictedTwaAtMarkDeg: 120,
            shiftConfidence: 'high',
            forecastBandDeg: 5,
            currentTwaDeg: 120,
          ),
      ];
      var t = highTicks;
      if (genuineLowBeforeFreeze) {
        // Valodi (nem-null) predikcio, de low konfidencia.
        snaps.add(
          RoundingSample(
            tickTime: base.add(Duration(seconds: t)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            predictedTwaAtMarkDeg: 120,
            shiftConfidence: 'low',
            currentTwaDeg: 120,
          ),
        );
        t++;
      }
      for (var i = 0; i < freezeTicks; i++) {
        // Freeze: a predikcio null, a konfidencia low (ADR 0021 50 m).
        snaps.add(
          RoundingSample(
            tickTime: base.add(Duration(seconds: t + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            shiftConfidence: 'low',
            currentTwaDeg: 120,
          ),
        );
      }
      final legStart = t + freezeTicks;
      for (var i = 0; i < 31; i++) {
        snaps.add(
          RoundingSample(
            tickTime: base.add(Duration(seconds: legStart + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'B',
            currentTwaDeg: -117,
            bearingToMarkDeg: 90,
            cogDeg: 90,
          ),
        );
      }
      return snaps;
    }

    test('a freeze-t athidalja: a pre-freeze high run-rol a korozesig', () {
      // ARRANGE — 10 high tick, majd 5 freeze tick (null predikcio, low),
      // majd a 'B' leg. A korozes a base+15s-nel. A regi logika null-t
      // adott (roundIndex-1 = freeze, low); az uj a high run elejetol mer.
      final snaps = withFreeze();

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — 10 mp high run + 5 mp freeze a korozesig = 15 mp.
      expect(result.leadTime, const Duration(seconds: 15));
      // a predikalt ertek is a pre-freeze high tickbol jon (nem null).
      expect(result.predictedTwaDeg, 120);
      expect(result.predictedConfidence, 'high');
    });

    test(
      'null, ha az utolso valodi predikcio nem megbizhato (genuine-low)',
      () {
        // ARRANGE — high run, majd EGY genuine-low (nem-null, low) tick,
        // majd freeze, majd 'B'. Az utolso valodi predikcio nem megbizhato
        // -> a joslat nem maradt megbizhato a rakozelitesig (D2).
        final snaps = withFreeze(genuineLowBeforeFreeze: true);

        // ACT
        final result = analyze(snaps).single;

        // ASSERT
        expect(result.leadTime, isNull);
      },
    );
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
}
