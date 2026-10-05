import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/season_stats/season_formatters.dart';

void main() {
  group('formatSeasonHours', () {
    test('gives hours with one decimal comma', () {
      expect(formatSeasonHours(const Duration(hours: 37, minutes: 30)), '37,5');
    });

    test('stays in hours below one hour', () {
      expect(formatSeasonHours(const Duration(minutes: 48)), '0,8');
    });
  });

  group('formatAveragePlace', () {
    test('gives one decimal comma', () {
      expect(formatAveragePlace(4.26), '4,3');
      expect(formatAveragePlace(2), '2,0');
    });
  });
}
