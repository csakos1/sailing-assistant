import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/theme/night_mode_provider.dart';

void main() {
  ProviderContainer containerAt(UtcClock clock) => ProviderContainer(
    overrides: [utcClockProvider.overrideWithValue(clock)],
  );

  group('nightModeProvider', () {
    test('is day at midday and night after sunset in June', () {
      // A referencia-ponton 2026-06-21-en a napnyugta kb. 18:47 UTC.
      final midday = containerAt(() => DateTime.utc(2026, 6, 21, 10));
      addTearDown(midday.dispose);
      final evening = containerAt(() => DateTime.utc(2026, 6, 21, 20));
      addTearDown(evening.dispose);

      expect(midday.read(nightModeProvider), isFalse);
      expect(evening.read(nightModeProvider), isTrue);
    });

    test('is night before sunrise', () {
      // Napkelte kb. 02:54 UTC ugyanezen a napon.
      final beforeDawn = containerAt(() => DateTime.utc(2026, 6, 21, 1));
      addTearDown(beforeDawn.dispose);

      expect(beforeDawn.read(nightModeProvider), isTrue);
    });

    test('the same clock hour is night in December, day in June', () {
      // 17:00 UTC: decemberben mar lement a nap (kb. 15:03), juniusban nem.
      final winter = containerAt(() => DateTime.utc(2026, 12, 21, 17));
      addTearDown(winter.dispose);
      final summer = containerAt(() => DateTime.utc(2026, 6, 21, 17));
      addTearDown(summer.dispose);

      expect(winter.read(nightModeProvider), isTrue);
      expect(summer.read(nightModeProvider), isFalse);
    });

    testWidgets('flips to night when the clock crosses sunset', (tester) async {
      // A widget-teszt a body VEGEN ellenorzi a fuggo timereket, a tearDownok
      // ELOTT: a containert ezert helyben kell eldobni, meg az assert elott.
      var now = DateTime.utc(2026, 6, 21, 18, 40);
      final container = containerAt(() => now);
      final beforeSunset = container.read(nightModeProvider);

      now = DateTime.utc(2026, 6, 21, 19, 40);
      await tester.pump(nightModeReevaluationPeriod);
      final afterSunset = container.read(nightModeProvider);
      container.dispose();

      expect(beforeSunset, isFalse);
      expect(afterSunset, isTrue);
    });

    testWidgets('does not notify while the answer stays the same', (
      tester,
    ) async {
      // A tema-csere a teljes fat ujraepiti, ezert a valtozatlan
      // ujraertekeles nem irhat allapotot.
      final container = containerAt(() => DateTime.utc(2026, 6, 21, 10));
      var notifications = 0;
      final sub = container.listen(
        nightModeProvider,
        (_, _) => notifications++,
      );

      await tester.pump(nightModeReevaluationPeriod * 3);
      sub.close();
      container.dispose();

      expect(notifications, 0);
    });
  });
}
