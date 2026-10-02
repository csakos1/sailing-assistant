import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/local_instant.dart';
import 'package:race_archive_api/race_archive_api.dart';

// A tesztek helyi DateTime-mal dolgoznak, hogy a gep idozonajatol
// fuggetlenul ugyanazt a helyi napot es orat adjak.

void main() {
  // A `!` biztonsagos: letezo napok.
  final june13 = CalendarDate.tryFromParts(year: 2026, month: 6, day: 13)!;
  final june30 = CalendarDate.tryFromParts(year: 2026, month: 6, day: 30)!;

  group('localInstant', () {
    test('combines the local day and time into a UTC instant', () {
      final instant = localInstant(june13, (hour: 10, minute: 30, second: 5));

      expect(instant.isUtc, isTrue);
      expect(instant, DateTime(2026, 6, 13, 10, 30, 5).toUtc());
    });

    test('rolls the day offset into the next month', () {
      final instant = localInstant(june30, (
        hour: 1,
        minute: 0,
        second: 0,
      ), dayOffset: 1);

      expect(instant, DateTime(2026, 7, 1, 1).toUtc());
    });
  });

  group('local parts of an instant', () {
    test('give back the local day and time', () {
      final instant = DateTime(2026, 6, 13, 23, 59, 58).toUtc();

      expect(localDateOf(instant), june13);
      expect(localClockOf(instant), (hour: 23, minute: 59, second: 58));
    });
  });

  group('localDayOffset', () {
    test('counts calendar days, not 24 hour blocks', () {
      // 23:00 -> masnap 01:00 csak ket ora, de egy naptari nap.
      final finish = DateTime(2026, 6, 14, 1).toUtc();

      expect(localDayOffset(june13, finish), 1);
    });

    test('is zero on the same day and negative before it', () {
      expect(localDayOffset(june13, DateTime(2026, 6, 13, 18).toUtc()), 0);
      expect(localDayOffset(june13, DateTime(2026, 6, 12, 18).toUtc()), -1);
    });
  });
}
