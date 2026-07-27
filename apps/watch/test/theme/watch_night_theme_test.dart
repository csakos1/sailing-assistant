import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/theme/watch_colors.dart';
import 'package:watch/theme/watch_theme.dart';

void main() {
  group('watchNightColors', () {
    test('swaps the three text tokens for the orange ramp', () {
      expect(watchNightColors.text, const Color(0xFFEE5035));
      expect(watchNightColors.textSecondary, const Color(0xFFA63825));
      expect(watchNightColors.textTertiary, const Color(0xFF8C2F1F));
    });

    test('leaves every meaning-carrying colour untouched', () {
      // Ez a szelet igerete: csak a szoveg-rampa valt. Ha barmelyik allitas
      // bukik, a szinkod serult, nem a megjelenes valtozott.
      expect(watchNightColors.background, watchDayColors.background);
      expect(watchNightColors.surface, watchDayColors.surface);
      expect(watchNightColors.signal, watchDayColors.signal);
      expect(watchNightColors.critical, watchDayColors.critical);
      expect(watchNightColors.port, watchDayColors.port);
      expect(watchNightColors.starboard, watchDayColors.starboard);
      expect(watchNightColors.amber, watchDayColors.amber);
    });

    test('writes dark on the critical field where day writes light', () {
      expect(watchNightColors.onCritical, watchDayColors.background);
      expect(watchDayColors.onCritical, watchDayColors.text);
    });
  });

  group('WatchColors.onCritical default', () {
    test('an unspecified onCritical keeps the day appearance', () {
      const built = WatchColors(
        background: Color(0xFF04080D),
        surface: Color(0xFF0D1822),
        text: Color(0xFFE9F1F7),
        textSecondary: Color(0xFF93A8BA),
        textTertiary: Color(0xFF5C7285),
        signal: Color(0xFF16E0C4),
        critical: Color(0xFFFF4D4D),
        port: Color(0xFFFF5A52),
        starboard: Color(0xFF2FD06E),
      );

      expect(built.onCritical, const Color(0xFFE9F1F7));
    });

    test('copyWith and lerp carry onCritical through', () {
      final copied = watchDayColors.copyWith(
        onCritical: const Color(0xFF123456),
      );
      final halfway = watchDayColors.lerp(watchNightColors, 1);

      expect(copied.onCritical, const Color(0xFF123456));
      expect(halfway.onCritical, watchNightColors.onCritical);
    });
  });

  group('themes', () {
    test('the day theme still carries the original tokens', () {
      final colors = watchDarkTheme.extension<WatchColors>()!;

      expect(colors.text, const Color(0xFFE9F1F7));
      expect(colors.textSecondary, const Color(0xFF93A8BA));
      expect(colors.textTertiary, const Color(0xFF5C7285));
      expect(watchDarkTheme.scaffoldBackgroundColor, const Color(0xFF04080D));
    });

    test('the night theme carries the night token set', () {
      final colors = watchNightTheme.extension<WatchColors>()!;

      expect(colors, same(watchNightColors));
    });

    test('the night scheme keeps implicitly coloured text off white', () {
      expect(watchNightTheme.colorScheme.onSurface, watchNightColors.text);
      expect(
        watchNightTheme.colorScheme.onSurfaceVariant,
        watchNightColors.textSecondary,
      );
    });

    test('the day scheme is left to the seed, as before', () {
      // A nappali sema szandekosan valtozatlan: ez a szelet nem nyul hozza.
      expect(
        watchDarkTheme.colorScheme.onSurface,
        isNot(watchDayColors.text),
      );
      expect(watchDarkTheme.colorScheme.surface, const Color(0xFF0D1822));
    });
  });
}
