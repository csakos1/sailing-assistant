import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/l10n/app_localizations_hu.dart';

void main() {
  final l10n = AppLocalizationsHu();
  // Helyi idok: a formazok a telefon idozonajaban szamolnak.
  final now = DateTime(2026, 10, 8, 11, 30);

  group('formatWebMoment', () {
    test('today and yesterday carry the clock time', () {
      expect(
        formatWebMoment(l10n, DateTime(2026, 10, 8, 9, 12), now),
        'ma 09:12',
      );
      expect(
        formatWebMoment(l10n, DateTime(2026, 10, 7, 21, 40), now),
        'tegnap 21:40',
      );
    });

    test('earlier this year is the month and the day', () {
      expect(
        formatWebMoment(l10n, DateTime(2026, 10, 3, 8), now),
        'okt. 3.',
      );
    });

    test('an earlier year carries the year', () {
      expect(
        formatWebMoment(l10n, DateTime(2025, 8, 30, 8), now),
        '2025. aug. 30.',
      );
    });

    test('yesterday works across a year boundary', () {
      expect(
        formatWebMoment(
          l10n,
          DateTime(2025, 12, 31, 23, 5),
          DateTime(2026, 1, 1, 0, 10),
        ),
        'tegnap 23:05',
      );
    });
  });

  group('formatBannerMoment', () {
    test('a login today is just the clock time', () {
      expect(
        formatBannerMoment(l10n, DateTime(2026, 10, 8, 14, 32), now),
        '14:32',
      );
      expect(
        formatBannerMoment(l10n, DateTime(2026, 10, 7, 14, 32), now),
        'tegnap 14:32',
      );
    });
  });

  group('formatWebAgo', () {
    test('rounds down to minutes, hours and days', () {
      expect(
        formatWebAgo(l10n, now.subtract(const Duration(seconds: 59)), now),
        'most',
      );
      expect(
        formatWebAgo(l10n, now.subtract(const Duration(minutes: 2)), now),
        '2 perce',
      );
      expect(
        formatWebAgo(l10n, now.subtract(const Duration(minutes: 839)), now),
        '13 órája',
      );
      expect(
        formatWebAgo(l10n, now.subtract(const Duration(hours: 25)), now),
        '1 napja',
      );
    });

    test('a moment ahead of the phone clock is now', () {
      expect(
        formatWebAgo(l10n, now.add(const Duration(minutes: 3)), now),
        'most',
      );
    });
  });

  group('text parts', () {
    test('the place keeps only what is known', () {
      expect(placeOf(city: 'Budapest', country: 'HU'), 'Budapest, HU');
      expect(placeOf(country: 'HU'), 'HU');
      expect(placeOf(), isNull);
    });

    test('the browser line falls back to unknown', () {
      expect(
        browserLineOf(l10n, browser: 'Chrome', os: 'Android'),
        'Chrome · Android',
      );
      expect(browserLineOf(l10n, os: 'Linux'), 'Linux');
      expect(browserLineOf(l10n), 'Ismeretlen böngésző');
    });

    test('every month has a short name', () {
      expect(
        [for (var month = 1; month <= 12; month++) monthShortName(l10n, month)],
        hasLength(12),
      );
      expect(monthShortName(l10n, 9), 'szept.');
    });
  });

  group('formatExpiresIn', () {
    test('counts whole hours, rounding down', () {
      expect(
        formatExpiresIn(
          l10n,
          now.add(const Duration(hours: 23, minutes: 48)),
          now,
        ),
        'lejár 23 ó múlva',
      );
    });

    test('under an hour it counts minutes', () {
      expect(
        formatExpiresIn(l10n, now.add(const Duration(minutes: 12)), now),
        'lejár 12 p múlva',
      );
    });

    test('a few seconds left is still one minute', () {
      expect(
        formatExpiresIn(l10n, now.add(const Duration(seconds: 20)), now),
        'lejár 1 p múlva',
      );
    });
  });
}
