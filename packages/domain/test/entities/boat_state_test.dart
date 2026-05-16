import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Közös fixtúrák.
  const samplePosition = Coordinate(latitude: 46.9, longitude: 18.05);
  const sampleHdgMag = Bearing(
    degrees: 100,
    reference: BearingReference.magneticNorth,
  );
  const sampleHdgTrue = Bearing(
    degrees: 105,
    reference: BearingReference.trueNorth,
  );
  const sampleCog = Bearing(
    degrees: 110,
    reference: BearingReference.trueNorth,
  );
  // 3 m/s ≈ 5.83 csomó, jócskán a küszöb fölött.
  const sampleSog = Speed(metersPerSecond: 3);
  const sampleStw = Speed(metersPerSecond: 2.5);
  // 0.5 m/s ≈ 0.97 csomó, a küszöb alatt.
  const slowSog = Speed(metersPerSecond: 0.5);
  final sampleTimestamp = DateTime.utc(2025, 6, 1, 10);

  group('konstrukció', () {
    test('minden mezővel létrejön', () {
      final state = BoatState(
        position: samplePosition,
        headingMagnetic: sampleHdgMag,
        headingTrue: sampleHdgTrue,
        courseOverGround: sampleCog,
        speedOverGround: sampleSog,
        speedThroughWater: sampleStw,
        lastUpdate: sampleTimestamp,
      );

      expect(state.position, samplePosition);
      expect(state.headingMagnetic, sampleHdgMag);
      expect(state.headingTrue, sampleHdgTrue);
      expect(state.courseOverGround, sampleCog);
      expect(state.speedOverGround, sampleSog);
      expect(state.speedThroughWater, sampleStw);
      expect(state.lastUpdate, sampleTimestamp);
    });

    test('csak a kötelező mezővel: minden opcionális null', () {
      final state = BoatState(lastUpdate: sampleTimestamp);

      expect(state.position, isNull);
      expect(state.headingMagnetic, isNull);
      expect(state.headingTrue, isNull);
      expect(state.courseOverGround, isNull);
      expect(state.speedOverGround, isNull);
      expect(state.speedThroughWater, isNull);
    });
  });

  group('Bearing-reference invariáns assertek', () {
    test('headingMagnetic trueNorth-tal → AssertionError', () {
      expect(
        () => BoatState(
          lastUpdate: sampleTimestamp,
          headingMagnetic: const Bearing(
            degrees: 100,
            reference: BearingReference.trueNorth,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('headingTrue magneticNorth-tal → AssertionError', () {
      expect(
        () => BoatState(
          lastUpdate: sampleTimestamp,
          headingTrue: const Bearing(
            degrees: 105,
            reference: BearingReference.magneticNorth,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('courseOverGround magneticNorth-tal → AssertionError', () {
      expect(
        () => BoatState(
          lastUpdate: sampleTimestamp,
          courseOverGround: const Bearing(
            degrees: 110,
            reference: BearingReference.magneticNorth,
          ),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('equality (Equatable)', () {
    test('azonos mezők → egyenlő', () {
      final s1 = BoatState(
        position: samplePosition,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      final s2 = BoatState(
        position: samplePosition,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(s1, equals(s2));
      expect(s1.hashCode, s2.hashCode);
    });

    test('különböző position → nem egyenlő', () {
      final s1 = BoatState(
        position: samplePosition,
        lastUpdate: sampleTimestamp,
      );
      final s2 = BoatState(
        position: const Coordinate(latitude: 47, longitude: 18.1),
        lastUpdate: sampleTimestamp,
      );
      expect(s1, isNot(equals(s2)));
    });

    test('null vs non-null mező → nem egyenlő', () {
      final s1 = BoatState(lastUpdate: sampleTimestamp);
      final s2 = BoatState(
        lastUpdate: sampleTimestamp,
        speedOverGround: sampleSog,
      );
      expect(s1, isNot(equals(s2)));
    });
  });

  group('copyWith', () {
    test('egy mező változik, többi marad', () {
      final state = BoatState(
        position: samplePosition,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      final updated = state.copyWith(speedOverGround: sampleSog);

      expect(updated.speedOverGround, sampleSog);
      expect(updated.position, samplePosition);
      expect(updated.headingTrue, sampleHdgTrue);
    });

    test('null paraméter nem változtat', () {
      final state = BoatState(lastUpdate: sampleTimestamp);
      expect(state.copyWith(), equals(state));
    });
  });

  group('effectiveDirection', () {
    test('SOG > küszöb és COG ismert → COG', () {
      final state = BoatState(
        speedOverGround: sampleSog,
        courseOverGround: sampleCog,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, sampleCog);
    });

    test('SOG < küszöb és headingTrue ismert → headingTrue', () {
      final state = BoatState(
        speedOverGround: slowSog,
        courseOverGround: sampleCog,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, sampleHdgTrue);
    });

    test('SOG > küszöb de COG null → headingTrue '
        '(fall-back COG hiánya miatt)', () {
      final state = BoatState(
        speedOverGround: sampleSog,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, sampleHdgTrue);
    });

    test('SOG null és headingTrue ismert → headingTrue', () {
      final state = BoatState(
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, sampleHdgTrue);
    });

    test('csak headingMagnetic ismert (nincs headingTrue) → null', () {
      // A szigorú design: a magneticNorth-ra nem fall-backelünk.
      final state = BoatState(
        headingMagnetic: sampleHdgMag,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, isNull);
    });

    test('minden navigációs adat null → null', () {
      final state = BoatState(lastUpdate: sampleTimestamp);
      expect(state.effectiveDirection, isNull);
    });

    test('SOG pontosan a küszöbön (strict >) → headingTrue', () {
      // A küszöb (0.7717 m/s) szigorúan nagyobb feltétellel; pontos
      // egyenlőség esetén a heading-re esik vissza.
      final state = BoatState(
        speedOverGround: const Speed(metersPerSecond: 0.7717),
        courseOverGround: sampleCog,
        headingTrue: sampleHdgTrue,
        lastUpdate: sampleTimestamp,
      );
      expect(state.effectiveDirection, sampleHdgTrue);
    });
  });

  group('toString', () {
    test('tartalmazza a kulcs-mezőket', () {
      final state = BoatState(
        position: samplePosition,
        lastUpdate: sampleTimestamp,
      );
      final s = state.toString();
      expect(s, contains('BoatState'));
      expect(s, contains('Coordinate'));
    });
  });
}
