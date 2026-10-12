import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/race_setup/start_time/start_time_calendar.dart';

void main() {
  group('monthGridDays', () {
    test('starts on Monday with the leading blanks', () {
      // 2026. oktober 1. csutortok: harom ures cella (H, K, Sze).
      final days = monthGridDays(2026, 10);

      expect(days.take(4), [null, null, null, 1]);
      expect(days.last, 31);
      expect(days.whereType<int>(), hasLength(31));
    });

    test('has no blanks when the month starts on Monday', () {
      // 2026. junius 1. hetfo.
      expect(monthGridDays(2026, 6).first, 1);
    });

    test('puts six blanks before a Sunday start', () {
      // 2026. november 1. vasarnap.
      final days = monthGridDays(2026, 11);

      expect(days.take(7), [null, null, null, null, null, null, 1]);
      expect(days.last, 30);
    });

    test('knows leap-year February', () {
      expect(monthGridDays(2028, 2).last, 29);
      expect(monthGridDays(2026, 2).last, 28);
    });

    test('is not shifted by the daylight-saving change', () {
      // A marciusi es az oktoberi atallas honapja is 31 napos marad.
      expect(monthGridDays(2026, 3).whereType<int>(), hasLength(31));
      expect(monthGridDays(2026, 10).whereType<int>(), hasLength(31));
    });
  });

  group('defaultStartTime', () {
    test('rounds up to the next full hour on the same day', () {
      expect(
        defaultStartTime(DateTime(2026, 10, 12, 8, 30)),
        DateTime(2026, 10, 12, 9),
      );
    });

    test('moves on a full hour too', () {
      expect(
        defaultStartTime(DateTime(2026, 10, 12, 8)),
        DateTime(2026, 10, 12, 9),
      );
    });

    test('rolls over to the next day after 23:00', () {
      expect(
        defaultStartTime(DateTime(2026, 10, 31, 23, 10)),
        DateTime(2026, 11),
      );
    });
  });

  group('wrapStep', () {
    test('steps inside the range', () {
      expect(wrapStep(9, 1, 24), 10);
      expect(wrapStep(9, -1, 24), 8);
    });

    test('wraps the hour at both ends', () {
      expect(wrapStep(23, 1, 24), 0);
      expect(wrapStep(0, -1, 24), 23);
    });

    test('wraps the minute at both ends', () {
      expect(wrapStep(59, 1, 60), 0);
      expect(wrapStep(0, -1, 60), 59);
    });
  });

  group('shiftMonth', () {
    test('crosses the year in both directions', () {
      expect(shiftMonth(DateTime(2026, 12), 1), DateTime(2027));
      expect(shiftMonth(DateTime(2026), -1), DateTime(2025, 12));
    });
  });

  group('isSameLocalDay', () {
    test('ignores the time of day', () {
      expect(
        isSameLocalDay(DateTime(2026, 10, 12), DateTime(2026, 10, 12, 23, 59)),
        isTrue,
      );
      expect(
        isSameLocalDay(DateTime(2026, 10, 12, 23), DateTime(2026, 10, 13)),
        isFalse,
      );
    });
  });

  group('isBeforeLocalDay', () {
    test('is true only for an earlier day', () {
      final today = DateTime(2026, 10, 12, 8);

      expect(isBeforeLocalDay(DateTime(2026, 10, 11, 23), today), isTrue);
      expect(isBeforeLocalDay(DateTime(2026, 10, 12), today), isFalse);
      expect(isBeforeLocalDay(DateTime(2026, 10, 13), today), isFalse);
    });
  });
}
