import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_detail/detail_formatters.dart';

void main() {
  test('formats the YS number with two decimals and a comma', () {
    expect(formatYsNumber(7590), '75,90');
    expect(formatYsNumber(7505), '75,05');
    expect(formatYsNumber(10200), '102,00');
  });

  test('formats a local clock time', () {
    expect(formatLocalClock(DateTime(2026, 7, 26, 9, 5)), '09:05');
  });

  test('shows the seconds of a local clock time only when not zero', () {
    expect(formatLocalClock(DateTime(2026, 7, 26, 14, 32, 7)), '14:32:07');
    expect(formatLocalClock(DateTime(2026, 7, 26, 14, 32, 0, 400)), '14:32');
  });

  test('formats elapsed time past 24 hours in hours', () {
    expect(
      formatElapsed(const Duration(hours: 23, minutes: 35, seconds: 7)),
      '23:35:07',
    );
    expect(formatElapsed(const Duration(hours: 26, minutes: 1)), '26:01:00');
  });

  test('tells a finish on the next local day', () {
    final start = DateTime(2026, 7, 30, 9);

    expect(isNextLocalDay(start, DateTime(2026, 7, 30, 23, 59)), isFalse);
    expect(isNextLocalDay(start, DateTime(2026, 7, 31, 8, 35)), isTrue);
  });
}
