import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/polar/polar_formatters.dart';

void main() {
  group('formatPolarPct', () {
    test('rounds to one decimal with a decimal comma', () {
      expect(formatPolarPct(87.24), '87,2');
    });

    test('keeps the trailing zero', () {
      expect(formatPolarPct(100), '100,0');
    });
  });

  group('formatPolarShare', () {
    test('turns a share into a percentage', () {
      expect(formatPolarShare(0.401), '40,1');
    });

    test('shows an empty share as zero', () {
      expect(formatPolarShare(0), '0,0');
    });
  });

  group('formatHoursMinutes', () {
    test('pads the minutes after the hours', () {
      expect(
        formatHoursMinutes(const Duration(hours: 2, minutes: 5)),
        '2 ó 05 p',
      );
    });

    test('drops the hours under an hour', () {
      expect(formatHoursMinutes(const Duration(minutes: 48)), '48 p');
    });

    test('ignores the seconds', () {
      expect(
        formatHoursMinutes(const Duration(hours: 1, minutes: 2, seconds: 59)),
        '1 ó 02 p',
      );
    });
  });

  group('formatMeasuredHours', () {
    test('gives the hours with one decimal', () {
      // 58 ora 18 perc = 209 880 mp
      expect(formatMeasuredHours(209880), '58,3');
    });
  });
}
