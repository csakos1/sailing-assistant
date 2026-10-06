import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';

void main() {
  group('season day formats', () {
    test('give month and day within a year', () {
      expect(formatMonthDay(DateTime(2026, 6, 13)), '06.13.');
    });

    test('give the full date across years', () {
      expect(formatFullDay(DateTime(2024, 7, 25)), '2024.07.25.');
    });
  });

  group('formatPercent', () {
    test('rounds to a whole percent', () {
      // 5 / 14 = 35,7%
      expect(formatPercent(5, 14), '36%');
      expect(formatPercent(14, 14), '100%');
    });

    test('gives zero for no races', () {
      expect(formatPercent(0, 0), '0%');
    });
  });
}
