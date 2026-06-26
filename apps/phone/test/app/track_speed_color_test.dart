import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/marine_colors.dart';

void main() {
  group('colorForTrackSpeed', () {
    test('null sebesseg -> semleges szurke', () {
      expect(colorForTrackSpeed(null), trackSpeedUnknownColor);
    });

    test('0 m/s -> a legalso (zold) sav', () {
      // 0 kn -> 0. sav.
      expect(colorForTrackSpeed(0), const Color(0xFF2FB344));
    });

    test('kozepes sebesseg a vart savba esik', () {
      // 2 m/s = 3.888 kn -> 3. sav.
      expect(colorForTrackSpeed(2), const Color(0xFFD9C549));
    });

    test('gyors sebesseg -> a legfelso (piros) sav', () {
      // 4 m/s = 7.775 kn -> 7. sav.
      expect(colorForTrackSpeed(4), const Color(0xFFE5484D));
    });

    test('8 csomo felett a 7. savra clampel', () {
      // 5 m/s = 9.7 kn -> clamp -> 7. sav.
      expect(colorForTrackSpeed(5), const Color(0xFFE5484D));
    });
  });
}
