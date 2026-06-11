import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';

void main() {
  group('millisToNextSecond', () {
    test('null → 1000 ms fallback ütem', () {
      expect(millisToNextSecond(null), 1000);
    });

    test('a határig hátralévő ms-t adja', () {
      // 11:19:02.350 → 650 ms a következő határig
      expect(millisToNextSecond(DateTime.utc(2026, 6, 6, 11, 19, 2, 350)), 650);
    });

    test('pont a határon → teljes 1000 ms', () {
      expect(millisToNextSecond(DateTime.utc(2026, 6, 6, 11, 19, 2)), 1000);
    });

    test('a határ előtt 1 ms-mal → 1 ms', () {
      expect(millisToNextSecond(DateTime.utc(2026, 6, 6, 11, 19, 2, 999)), 1);
    });
  });
}
