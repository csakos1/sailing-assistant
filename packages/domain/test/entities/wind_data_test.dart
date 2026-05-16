import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Közös fixtúrák.
  const sampleAwa = Angle(degrees: 45);
  const sampleAws = Speed(metersPerSecond: 7);
  const sampleTwa = Angle(degrees: 35);
  const sampleTws = Speed(metersPerSecond: 6);
  const sampleTwd = Bearing(
    degrees: 180,
    reference: BearingReference.trueNorth,
  );
  final sampleTimestamp = DateTime.utc(2025, 6, 1, 10);

  group('konstrukció', () {
    test('minden mezővel létrejön', () {
      // ARRANGE & ACT
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        trueSpeedWater: sampleTws,
        trueDirectionGround: sampleTwd,
        timestamp: sampleTimestamp,
      );

      // ASSERT
      expect(wind.apparentAngle, sampleAwa);
      expect(wind.apparentSpeed, sampleAws);
      expect(wind.trueAngleWater, sampleTwa);
      expect(wind.trueSpeedWater, sampleTws);
      expect(wind.trueDirectionGround, sampleTwd);
      expect(wind.timestamp, sampleTimestamp);
    });

    test('csak a kötelező mezőkkel: opcionálisak null-ban', () {
      // ARRANGE & ACT
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );

      // ASSERT
      expect(wind.trueAngleWater, isNull);
      expect(wind.trueSpeedWater, isNull);
      expect(wind.trueDirectionGround, isNull);
    });
  });

  group('equality (Equatable)', () {
    test('azonos mezők → egyenlő', () {
      final wind1 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        timestamp: sampleTimestamp,
      );
      final wind2 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        timestamp: sampleTimestamp,
      );

      expect(wind1, equals(wind2));
      expect(wind1.hashCode, wind2.hashCode);
    });

    test('különböző AWA → nem egyenlő', () {
      final wind1 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final wind2 = WindData(
        apparentAngle: const Angle(degrees: 60),
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );

      expect(wind1, isNot(equals(wind2)));
    });

    test('TWA null vs non-null → nem egyenlő', () {
      final wind1 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final wind2 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        timestamp: sampleTimestamp,
      );

      expect(wind1, isNot(equals(wind2)));
    });

    test('különböző timestamp → nem egyenlő', () {
      final wind1 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final wind2 = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: DateTime.utc(2025, 6, 1, 10, 1),
      );

      expect(wind1, isNot(equals(wind2)));
    });
  });

  group('copyWith', () {
    test('egy mező változik, többi marad', () {
      // ARRANGE
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        timestamp: sampleTimestamp,
      );

      // ACT
      final updated = wind.copyWith(
        apparentAngle: const Angle(degrees: 60),
      );

      // ASSERT
      expect(updated.apparentAngle, const Angle(degrees: 60));
      expect(updated.apparentSpeed, sampleAws);
      expect(updated.trueAngleWater, sampleTwa);
      expect(updated.timestamp, sampleTimestamp);
    });

    test('null paraméter nem változtat', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final copy = wind.copyWith();
      expect(copy, equals(wind));
    });

    test('timestamp változik', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final later = DateTime.utc(2025, 6, 1, 10, 5);
      final updated = wind.copyWith(timestamp: later);

      expect(updated.timestamp, later);
      expect(updated.apparentAngle, wind.apparentAngle);
    });
  });

  group('hasTrueWind', () {
    test('minden true-wind null → false', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      expect(wind.hasTrueWind, isFalse);
    });

    test('csak TWA-water van → true', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        timestamp: sampleTimestamp,
      );
      expect(wind.hasTrueWind, isTrue);
    });

    test('csak TWS-water van → true', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueSpeedWater: sampleTws,
        timestamp: sampleTimestamp,
      );
      expect(wind.hasTrueWind, isTrue);
    });

    test('csak TWD-ground van → true', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueDirectionGround: sampleTwd,
        timestamp: sampleTimestamp,
      );
      expect(wind.hasTrueWind, isTrue);
    });

    test('mindhárom van → true', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        trueAngleWater: sampleTwa,
        trueSpeedWater: sampleTws,
        trueDirectionGround: sampleTwd,
        timestamp: sampleTimestamp,
      );
      expect(wind.hasTrueWind, isTrue);
    });
  });

  group('toString', () {
    test('tartalmazza a kulcs-mezőket', () {
      final wind = WindData(
        apparentAngle: sampleAwa,
        apparentSpeed: sampleAws,
        timestamp: sampleTimestamp,
      );
      final s = wind.toString();
      expect(s, contains('WindData'));
      expect(s, contains('Angle'));
      expect(s, contains('Speed'));
    });
  });
}
