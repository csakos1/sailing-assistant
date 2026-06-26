import 'package:domain/domain.dart';
import 'package:domain/src/_internal/wrap_angle.dart';
import 'package:test/test.dart';

void main() {
  const analyze = AnalyzeRoundings();
  final base = DateTime.utc(2026, 6, 6, 11);

  // Szintetikus korozes-folyam: `approachTicks` tick 'A'-n a megadott
  // predikcioval/konfidenciaval, majd `legTicks` tick 'B'-n a megadott
  // tenyleges TWA-val es COG-gal. A 'B'-tickek a leg-iranyt (bearingToMark)
  // is hordozzak, amire a counterfactual TWA vetul (ADR 0034 Addendum 2).
  // Alapbol a COG = a leg-irany (= ramentem a bojara), igy a counterfactual
  // megegyezik a tenyleges TWA-val (a regi viselkedes specialis esete).
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
    test('predikalt vs leg-vetitett, savon belul, lead-time', () {
      // ARRANGE — ramentem a bojara (COG = legBearing = 90), igy a
      // counterfactual = a tenyleges TWA: wrapTo180(90 + -117 - 90) = -117.
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
      expect(result.markTwaDeg, closeTo(-117, 1e-6));
      expect(result.deltaDeg, closeTo(3, 1e-6));
      expect(result.isWithinBand, isTrue);
      // 10 megszakitatlan 'high' tick a korozesig.
      expect(result.leadTime, const Duration(seconds: 10));
      // Freeze nelkul a horgony az utolso pre-round tick: 1 mp az ablak vege.
      expect(result.lastReliableLeadTime, const Duration(seconds: 1));
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
      // tickek COG-ja stabil (a kapu nyit, a leg-vetitett TWA merheto).
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
      expect(result.markTwaDeg, closeTo(-117, 1e-6)); // a vetitett megvan
    });

    test('lead-time null, ha a korozeskor nem volt megbizhato', () {
      // ARRANGE — az approach-tickek vegig low konfidenciaval.
      final snaps = scenario(confidence: 'low');

      // ACT
      final result = analyze(snaps).single;

      // ASSERT
      expect(result.leadTime, isNull);
      expect(result.lastReliableLeadTime, isNull);
    });
  });

  group('counterfactual leg-vetites (ADR 0034 Addendum 2)', () {
    test('no-go leg: nem mentem ra, de a vetites a leg-iranyra helyes', () {
      // ARRANGE — a leg-irany 0 fok (eszak), amit nem lehet vitorlazni
      // (szelbe). Felelezek: tartosan COG 40 fok-on megyek (off-leg), a
      // tenyleges TWA igy -40. A tenyleges szel (TWD = COG + TWA = 0) viszont
      // a leg-iranybol nezve 0 fok TWA-t adna -> a regi "tenyleges" -40-et
      // mert volna (szennyezve a navigaciotol), a counterfactual a helyes 0-t.
      final snaps = <RoundingSample>[
        for (var i = 0; i < 10; i++)
          RoundingSample(
            tickTime: base.add(Duration(seconds: i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'A',
            predictedTwaAtMarkDeg: 2,
            shiftConfidence: 'high',
            forecastBandDeg: 5,
            currentTwaDeg: 2,
          ),
        for (var i = 0; i < 31; i++)
          RoundingSample(
            tickTime: base.add(Duration(seconds: 10 + i)),
            raceStatus: 'active',
            twdQuality: 'live',
            markName: 'B',
            currentTwaDeg: -40, // felelezve, off-leg vitorlazott szog
            bearingToMarkDeg: 0, // a leg eszakra tart (nem vitorlazhato)
            cogDeg: 40, // tartosan 40 fok-on megyek, NEM a leg fele
          ),
      ];

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a counterfactual: wrapTo180(40 + -40 - 0) = 0; a delta a
      // predikalt 2-hoz kepest -2 (savon belul), NEM a -40-bol szamolt zaj.
      expect(result.markTwaDeg, closeTo(0, 1e-6));
      expect(result.deltaDeg, closeTo(-2, 1e-6));
      expect(result.isWithinBand, isTrue);
      expect(result.actualSampleCount, 20);
    });
  });

  group('steady-COG beallasi kapu (ADR 0026 / Addendum 2 A2-D3)', () {
    // Egy korozes 'high' approach-csal; a 'B' legen elobb forgo COG
    // (atmenet), majd a megadott pillanattol stabil COG (beallt).
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
      // Az "atmenet" tickjein a COG vForog: paratlanul 0, parosan 180 — igy
      // egyik szomszedos tick sem stabil a masikhoz (a steady-COG kapu nem
      // nyit). A fluke-offseteken a stabil onCog (de magaban keves).
      for (var i = 0; i < offTicks; i++) {
        final spinning = i.isEven ? 0.0 : 180.0;
        final cog = flukeOffsets.contains(i) ? onCog : spinning;
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

    test('a kapu csak a COG beallasanal nyilik (nem a forgo atmeneten)', () {
      // ARRANGE — 60 tick forgo COG, majd 30 tick stabil (COG 90).
      final snaps = lateSettle(offTicks: 60, onTicks: 30);

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a beallt szakaszrol mer: counterfactual
      // wrapTo180(90 + 118 - 90) = 118, nem az atmeneti zaj.
      expect(result.markTwaDeg, closeTo(118, 1e-6));
      expect(result.predictedTwaDeg, 120);
      expect(result.deltaDeg, closeTo(-2, 1e-6));
    });

    test('sosem all be: a COG vegig forog -> n/a', () {
      // ARRANGE — 60 tick forgo COG, soha nincs stabil szakasz.
      final snaps = lateSettle(offTicks: 60, onTicks: 0);

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — nincs beallt ablak, a vetitett n/a; a predikalt megvan.
      expect(result.markTwaDeg, isNull);
      expect(result.actualSampleCount, 0);
      expect(result.deltaDeg, isNull);
      expect(result.predictedTwaDeg, 120);
    });

    test('debounce: egyetlen fluke stabil tick nem nyitja a kaput', () {
      // ARRANGE — a forgo atmenet 20. tickjenel (base+30s) egyetlen
      // stabil-iranyu COG; a tartos beallas csak utana. A 3 s debounce eldobja
      // (a kovetkezo forgo tick ujra kifut a toleranciabol).
      final snaps = lateSettle(
        offTicks: 25,
        onTicks: 30,
        flukeOffsets: const [20],
      );

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a fluke nem nyit; a beallt 118 jon.
      expect(result.markTwaDeg, closeTo(118, 1e-6));
    });

    test('off-leg de stabil COG: a kapu nyit (steady-COG)', () {
      // ARRANGE — a 'B' legen a COG vegig 270 (NEM a leg fele, ami 90), de
      // onmagahoz stabil. A regi leg-relativ kapu sosem nyitott volna (a 20-as
      // tol mellett); a steady-COG kapu nyit. A counterfactual a tenyleges
      // szelet a leg-iranyra vetiti: wrapTo180(270 + -117 - 90) = 63.
      final snaps = scenario(legCogDeg: 270);

      // ACT
      final result = analyze(snaps).single;

      // ASSERT — a kapu a floor-nal nyit (a 270 onmagahoz stabil), 20 minta;
      // a vetitett TWA 63 (NEM a -117 tenyleges, mert nem a leg fele megyek).
      expect(result.actualSampleCount, 20);
      expect(result.markTwaDeg, closeTo(63, 1e-6));
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
      // a "meddig": az utolso valodi predikcio (a freeze elott) 6 mp-re van.
      expect(result.lastReliableLeadTime, const Duration(seconds: 6));
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
        expect(result.lastReliableLeadTime, isNull);
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
