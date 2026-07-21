import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const useCase = EvaluateDepthAlert();
  const idle = DepthAlertState();

  // Rövidítés: a use case hívása nyers méter-értékkel. `null` mélység =
  // nem jött használható DPT/DBT.
  DepthAlertState evaluate(
    DepthAlertState previous,
    double? meters, {
    bool isConnected = true,
  }) {
    return useCase(
      previous: previous,
      depth: meters == null ? null : Depth(meters: meters),
      isConnected: isConnected,
    );
  }

  group('EvaluateDepthAlert', () {
    group('belépés', () {
      test('a triggert elérve aktiválódik és rezeg', () {
        final state = evaluate(idle, 2.5);

        expect(state.isActive, isTrue);
        expect(state.lowestBuzzedBucket, equals(2.5));
        expect(state.buzzCounter, equals(1));
      });

      test('a hiszterézis-sávban inaktívból nem indul epizód', () {
        // 2.5 < 2.7 < 3.0: a sáv csak a MÁR AKTÍV epizódot tartja
        // életben, újat nem indít.
        final state = evaluate(idle, 2.7);

        expect(state, equals(idle));
      });

      test('mély vízen nem történik semmi', () {
        final state = evaluate(idle, 8.4);

        expect(state, equals(idle));
      });

      test('a mélységet lefelé kerekíti 0,1 m-es vödörre', () {
        final state = evaluate(idle, 2.37);

        expect(state.lowestBuzzedBucket, equals(2.3));
      });
    });

    group('ratchet', () {
      const active = DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: 2.3,
        buzzCounter: 1,
      );

      test('új mélypont újra rezeg és lejjebb viszi a horgonyt', () {
        final state = evaluate(active, 2.1);

        expect(state.isActive, isTrue);
        expect(state.lowestBuzzedBucket, equals(2.1));
        expect(state.buzzCounter, equals(2));
      });

      test('azonos vödrön belüli ingadozás nem rezeg', () {
        // 2.34 ugyanabba a 2.3-as vödörbe esik, mint a horgony.
        final state = evaluate(active, 2.34);

        expect(state, equals(active));
      });

      test('már látott szintre visszaesve nem rezeg', () {
        // Feljebb jött, majd újra le — de csak 2.4-ig, ami már volt.
        final afterRise = evaluate(active, 2.45);
        final afterFall = evaluate(afterRise, 2.4);

        expect(afterFall, equals(active));
      });

      test('a hiszterézis-sávban aktív marad, de nem rezeg', () {
        final state = evaluate(active, 2.8);

        expect(state, equals(active));
      });
    });

    group('epizód lezárása', () {
      const active = DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: 2.1,
        buzzCounter: 3,
      );

      test('a clear küszöbön lezárul, a számláló megmarad', () {
        final state = evaluate(active, 3);

        expect(state.isActive, isFalse);
        expect(state.lowestBuzzedBucket, isNull);
        expect(state.buzzCounter, equals(3));
      });

      test('zárás után az újbóli belépés újra rezeg', () {
        final closed = evaluate(active, 4.2);
        final reentered = evaluate(closed, 2.4);

        expect(reentered.isActive, isTrue);
        expect(reentered.lowestBuzzedBucket, equals(2.4));
        expect(reentered.buzzCounter, equals(4));
      });
    });

    group('robusztusság', () {
      const active = DepthAlertState(
        isActive: true,
        lowestBuzzedBucket: 2.2,
        buzzCounter: 5,
      );

      test('szétkapcsolva reset, a számláló megmarad', () {
        // Stale adaton nem riasztunk (ADR 0014 D5 összhang).
        final state = evaluate(active, 1.8, isConnected: false);

        expect(state.isActive, isFalse);
        expect(state.lowestBuzzedBucket, isNull);
        expect(state.buzzCounter, equals(5));
      });

      test('hiányzó mélységnél az állapot változatlan', () {
        // Egy kieső mondat nem zárhat le futó epizódot.
        final state = evaluate(active, null);

        expect(state, equals(active));
      });

      test('a számláló egy teljes menet során sem csökken', () {
        const profile = [
          9.4,
          2.4,
          2.2,
          2.6,
          2.9,
          2.1,
          3.4,
          2.5,
          null,
          1.9,
          11.5,
        ];

        var state = idle;
        var previousCounter = 0;
        for (final meters in profile) {
          state = evaluate(state, meters);
          expect(state.buzzCounter, greaterThanOrEqualTo(previousCounter));
          previousCounter = state.buzzCounter;
        }

        expect(state.isActive, isFalse);
        expect(state.buzzCounter, equals(5));
      });
    });
  });
}
