import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Közös fixtúrák.
  const sampleTwd = Bearing(
    degrees: 220,
    reference: BearingReference.trueNorth,
  );
  final sampleTimestamp = DateTime.utc(2025, 6, 1, 10);

  group('konstrukció', () {
    test('minden mezővel létrejön', () {
      // ARRANGE & ACT
      final obs = WindObservation(
        twd: sampleTwd,
        timestamp: sampleTimestamp,
      );

      // ASSERT
      expect(obs.twd, sampleTwd);
      expect(obs.timestamp, sampleTimestamp);
    });
  });

  group('Bearing-reference invariáns', () {
    test('twd magneticNorth-tal → AssertionError', () {
      expect(
        () => WindObservation(
          twd: const Bearing(
            degrees: 220,
            reference: BearingReference.magneticNorth,
          ),
          timestamp: sampleTimestamp,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('equality (Equatable)', () {
    test('azonos mezők → egyenlő', () {
      final o1 = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);
      final o2 = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);

      expect(o1, equals(o2));
      expect(o1.hashCode, o2.hashCode);
    });

    test('különböző twd → nem egyenlő', () {
      final o1 = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);
      final o2 = WindObservation(
        twd: const Bearing(
          degrees: 225,
          reference: BearingReference.trueNorth,
        ),
        timestamp: sampleTimestamp,
      );

      expect(o1, isNot(equals(o2)));
    });

    test('különböző timestamp → nem egyenlő', () {
      final o1 = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);
      final o2 = WindObservation(
        twd: sampleTwd,
        timestamp: DateTime.utc(2025, 6, 1, 10, 5),
      );

      expect(o1, isNot(equals(o2)));
    });
  });

  group('copyWith', () {
    test('egy mező változik, másik marad', () {
      final obs = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);
      final newTimestamp = DateTime.utc(2025, 6, 1, 10, 5);

      final updated = obs.copyWith(timestamp: newTimestamp);

      expect(updated.twd, sampleTwd);
      expect(updated.timestamp, newTimestamp);
    });

    test('null paraméter nem változtat', () {
      final obs = WindObservation(twd: sampleTwd, timestamp: sampleTimestamp);
      final copy = obs.copyWith();
      expect(copy, equals(obs));
    });
  });
}
