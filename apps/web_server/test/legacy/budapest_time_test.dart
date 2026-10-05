import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/budapest_time.dart';

void main() {
  group('budapestWallClockToUtc', () {
    test('uses UTC+1 in winter', () {
      // ACT
      final utc = budapestWallClockToUtc(DateTime.utc(2026, 1, 15, 10));

      // ASSERT
      expect(utc, DateTime.utc(2026, 1, 15, 9));
    });

    test('uses UTC+2 in summer', () {
      // ACT
      final utc = budapestWallClockToUtc(DateTime.utc(2026, 7, 30, 9));

      // ASSERT
      expect(utc, DateTime.utc(2026, 7, 30, 7));
    });

    test('switches to summer time on the last Sunday of March', () {
      // ARRANGE: 2026-03-29 is the last Sunday of March
      final beforeSwitch = DateTime.utc(2026, 3, 29, 1, 59);
      final afterSwitch = DateTime.utc(2026, 3, 29, 3);

      // ACT & ASSERT
      expect(
        budapestWallClockToUtc(beforeSwitch),
        DateTime.utc(2026, 3, 29, 0, 59),
      );
      expect(budapestWallClockToUtc(afterSwitch), DateTime.utc(2026, 3, 29, 1));
    });

    test('reads the skipped spring hour with the winter offset', () {
      // ACT: 02:30 does not exist on 2026-03-29
      final utc = budapestWallClockToUtc(DateTime.utc(2026, 3, 29, 2, 30));

      // ASSERT
      expect(utc, DateTime.utc(2026, 3, 29, 1, 30));
    });

    test('reads the repeated autumn hour with the winter offset', () {
      // ACT: 02:30 occurs twice on 2026-10-25
      final utc = budapestWallClockToUtc(DateTime.utc(2026, 10, 25, 2, 30));

      // ASSERT
      expect(utc, DateTime.utc(2026, 10, 25, 1, 30));
    });

    test('keeps summer time before the autumn switch', () {
      // ACT
      final utc = budapestWallClockToUtc(DateTime.utc(2026, 10, 25, 1, 30));

      // ASSERT
      expect(utc, DateTime.utc(2026, 10, 24, 23, 30));
    });

    test('keeps the seconds', () {
      // ACT
      final utc = budapestWallClockToUtc(DateTime.utc(2021, 5, 15, 15, 47, 58));

      // ASSERT
      expect(utc, DateTime.utc(2021, 5, 15, 13, 47, 58));
    });
  });

  group('budapestWallClockOf', () {
    test('is the inverse of budapestWallClockToUtc in summer', () {
      // ACT
      final local = budapestWallClockOf(DateTime.utc(2026, 7, 30, 7, 0, 5));

      // ASSERT
      expect(local, DateTime.utc(2026, 7, 30, 9, 0, 5));
    });
  });

  group('budapestDayOf', () {
    test('rolls a late summer evening in UTC to the next local day', () {
      // ACT: 22:30Z is 00:30 local
      final day = budapestDayOf(DateTime.utc(2026, 7, 30, 22, 30));

      // ASSERT
      expect(day, CalendarDate.tryParse('2026-07-31'));
    });

    test('rolls a late winter evening in UTC to the next local day', () {
      // ACT: 23:30Z is 00:30 local
      final day = budapestDayOf(DateTime.utc(2026, 1, 1, 23, 30));

      // ASSERT
      expect(day, CalendarDate.tryParse('2026-01-02'));
    });

    test('keeps the day of a morning race', () {
      // ACT
      final day = budapestDayOf(DateTime.utc(2026, 6, 13, 8));

      // ASSERT
      expect(day, CalendarDate.tryParse('2026-06-13'));
    });
  });

  group('nextCalendarDay', () {
    test('crosses the year boundary', () {
      // ACT
      final next = nextCalendarDay(CalendarDate.tryParse('2026-12-31')!);

      // ASSERT
      expect(next, CalendarDate.tryParse('2027-01-01'));
    });

    test('knows the leap day', () {
      // ACT
      final next = nextCalendarDay(CalendarDate.tryParse('2028-02-28')!);

      // ASSERT
      expect(next, CalendarDate.tryParse('2028-02-29'));
    });
  });
}
