import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/clock_format.dart';

void main() {
  test('formats a clock time with two digits', () {
    expect(formatClock(DateTime(2026, 7, 30, 7, 3)), '07:03');
    expect(formatClock(DateTime(2026, 7, 30, 23, 45)), '23:45');
  });

  test('formats a clock time with seconds', () {
    expect(formatClockWithSeconds(DateTime(2026, 7, 30, 9, 0, 5)), '09:00:05');
  });
}
