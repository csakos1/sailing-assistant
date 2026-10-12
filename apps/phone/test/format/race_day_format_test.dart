import 'package:flutter_test/flutter_test.dart';
import 'package:phone/format/race_day_format.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();
  final today = DateTime(2026, 10, 12, 8);

  group('formatRaceDate', () {
    test('writes the month in capitals within this year', () {
      expect(
        formatRaceDate(l10n, DateTime(2026, 10, 11, 10), localToday: today),
        'OKT. 11.',
      );
    });

    test('adds the year in another year', () {
      expect(
        formatRaceDate(l10n, DateTime(2027, 1, 3, 9), localToday: today),
        '2027. JAN. 3.',
      );
    });
  });

  group('formatRaceDay', () {
    test('says today for a start on the same day', () {
      expect(
        formatRaceDay(l10n, DateTime(2026, 10, 12, 23, 30), localToday: today),
        'MA',
      );
    });

    test('writes the date for another day', () {
      expect(
        formatRaceDay(l10n, DateTime(2026, 10, 13, 9), localToday: today),
        'OKT. 13.',
      );
    });
  });

  group('formatRaceStart', () {
    test('shows only the time for a start today', () {
      expect(
        formatRaceStart(l10n, DateTime(2026, 10, 12, 9), localToday: today),
        '09:00',
      );
    });

    test('shows the day and the time for another day', () {
      expect(
        formatRaceStart(l10n, DateTime(2026, 10, 13, 9), localToday: today),
        'OKT. 13. 09:00',
      );
    });
  });
}
