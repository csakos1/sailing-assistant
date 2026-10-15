import 'package:data/src/engine/target_speed_percent.dart';
import 'package:test/test.dart';

void main() {
  group('targetSpeedPercent', () {
    test('converts the live m/s speed to knots and returns the ratio', () {
      // 3 m/s = 5.831532 kn; target 7 kn -> 83.31%.
      final percent = targetSpeedPercent(
        liveSpeedMetersPerSecond: 3,
        targetSpeedKnots: 7,
      );

      expect(percent, closeTo(83.3076, 1e-3));
    });

    test('is null without a live speed', () {
      expect(
        targetSpeedPercent(
          liveSpeedMetersPerSecond: null,
          targetSpeedKnots: 7,
        ),
        isNull,
      );
    });

    test('is null without a target (no-go zone)', () {
      expect(
        targetSpeedPercent(
          liveSpeedMetersPerSecond: 3,
          targetSpeedKnots: null,
        ),
        isNull,
      );
    });

    test('is null when the target is not positive', () {
      expect(
        targetSpeedPercent(liveSpeedMetersPerSecond: 3, targetSpeedKnots: 0),
        isNull,
      );
    });
  });
}
