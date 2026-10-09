import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';

void main() {
  group('CalendarDate.tryParse', () {
    test('reads a YYYY-MM-DD date and writes it back unchanged', () {
      // ACT
      final date = CalendarDate.tryParse('2026-06-13');

      // ASSERT
      expect(date?.year, 2026);
      expect(date?.month, 6);
      expect(date?.day, 13);
      expect(date?.toIso(), '2026-06-13');
    });

    test('accepts a leap day only in a leap year', () {
      expect(CalendarDate.tryParse('2024-02-29'), isNotNull);
      expect(CalendarDate.tryParse('2026-02-29'), isNull);
    });

    test('rejects days that do not exist', () {
      expect(CalendarDate.tryParse('2026-04-31'), isNull);
      expect(CalendarDate.tryParse('2026-13-01'), isNull);
      expect(CalendarDate.tryParse('2026-00-10'), isNull);
      expect(CalendarDate.tryParse('2026-06-00'), isNull);
      expect(CalendarDate.tryParse('0000-06-13'), isNull);
    });

    test('rejects other shapes, including the Hungarian dotted form', () {
      expect(CalendarDate.tryParse('2026.06.13'), isNull);
      expect(CalendarDate.tryParse('2026-6-13'), isNull);
      expect(CalendarDate.tryParse(' 2026-06-13'), isNull);
      expect(CalendarDate.tryParse('2026-06-13T00:00'), isNull);
      expect(CalendarDate.tryParse(''), isNull);
    });
  });

  group('CalendarDate', () {
    test('pads the year, month and day to a fixed width', () {
      final date = CalendarDate.tryFromParts(year: 812, month: 1, day: 2);

      expect(date?.toIso(), '0812-01-02');
    });

    test('compares chronologically', () {
      // ARRANGE
      final dates = [
        CalendarDate.tryParse('2026-01-05')!,
        CalendarDate.tryParse('2025-12-31')!,
        CalendarDate.tryParse('2026-01-04')!,
      ];

      // ACT
      final sorted = [...dates]..sort();

      // ASSERT
      expect(sorted.map((date) => date.toIso()), [
        '2025-12-31',
        '2026-01-04',
        '2026-01-05',
      ]);
    });

    test('is equal by value', () {
      expect(
        CalendarDate.tryParse('2026-06-13'),
        CalendarDate.tryFromParts(year: 2026, month: 6, day: 13),
      );
    });
  });
}
