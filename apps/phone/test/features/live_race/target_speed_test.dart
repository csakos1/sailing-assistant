import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/target_speed.dart';

void main() {
  group('targetSpeedPercent', () {
    test('a live m/s sebességet csomóra váltja és arányt számol', () {
      // STW 3 m/s = 5.8315 kn; cél 7 kn → 83.31%.
      final percent = targetSpeedPercent(
        liveSpeedMetersPerSecond: 3,
        targetSpeedKnots: 7,
      );
      expect(percent, closeTo(83.3076, 1e-3));
    });

    test('null, ha nincs élő sebesség', () {
      expect(
        targetSpeedPercent(
          liveSpeedMetersPerSecond: null,
          targetSpeedKnots: 7,
        ),
        isNull,
      );
    });

    test('null, ha nincs cél (no-go zóna)', () {
      expect(
        targetSpeedPercent(
          liveSpeedMetersPerSecond: 3,
          targetSpeedKnots: null,
        ),
        isNull,
      );
    });

    test('null, ha a cél nem pozitív', () {
      expect(
        targetSpeedPercent(
          liveSpeedMetersPerSecond: 3,
          targetSpeedKnots: 0,
        ),
        isNull,
      );
    });
  });

  group('formatTargetSpeedPercent', () {
    test('null → gondolatjel', () {
      expect(formatTargetSpeedPercent(null), '—');
    });

    test('egész százalékra kerekít', () {
      expect(formatTargetSpeedPercent(83.3076), '83%');
    });

    test('100% fölött is helyes', () {
      expect(formatTargetSpeedPercent(108.7), '109%');
    });
  });
}
