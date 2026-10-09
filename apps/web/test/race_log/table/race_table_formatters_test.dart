import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_log/table/race_table_formatters.dart';

void main() {
  test('formats the race day with dots and leading zeros', () {
    expect(formatTableDate(DateTime(2026, 6, 3)), '2026.06.03');
  });

  test('formats a clock time without seconds', () {
    expect(formatTableClock(DateTime(2026, 7, 26, 9, 5, 42)), '09:05');
  });

  test('formats the distance in kilometres even below one', () {
    expect(formatTableKilometers(172300), '172,3');
    expect(formatTableKilometers(840), '0,8');
  });

  test('formats a speed in knots with one decimal', () {
    // 5 m/s = 9,72 kn
    expect(formatTableKnots(5), '9,7');
  });
}
