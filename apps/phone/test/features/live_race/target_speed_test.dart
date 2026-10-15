import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/target_speed.dart';

void main() {
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
