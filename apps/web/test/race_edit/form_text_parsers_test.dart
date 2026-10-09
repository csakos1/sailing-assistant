import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_edit/form/clock_time.dart';
import 'package:foretack_web/race_edit/form/field_problem.dart';
import 'package:foretack_web/race_edit/form/form_text_parsers.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

void main() {
  group('parseWholeNumber', () {
    test('reads digits and trims spaces', () {
      expect(parseWholeNumber(' 24 '), const Ok<int?, TextFormat>(24));
    });

    test('treats blank text as not given', () {
      expect(parseWholeNumber('   '), const Ok<int?, TextFormat>(null));
    });

    test('rejects signs, decimals and letters', () {
      for (final text in ['-3', '3,5', '3.', 'harom', '1234567']) {
        expect(
          parseWholeNumber(text),
          const Err<int?, TextFormat>(TextFormat.wholeNumber),
          reason: text,
        );
      }
    });
  });

  group('parseDecimal', () {
    test('accepts a comma or a point', () {
      expect(parseDecimal('10,2'), const Ok<double?, TextFormat>(10.2));
      expect(parseDecimal('10.2'), const Ok<double?, TextFormat>(10.2));
      expect(parseDecimal('8'), const Ok<double?, TextFormat>(8));
    });

    test('rejects a negative number and stray characters', () {
      for (final text in ['-1', '1,2,3', '1 km']) {
        expect(
          parseDecimal(text),
          const Err<double?, TextFormat>(TextFormat.decimalNumber),
          reason: text,
        );
      }
    });
  });

  group('parseYsNumber', () {
    test('reads hundredths with a comma or a point', () {
      expect(parseYsNumber('75,90'), const Ok<int?, TextFormat>(7590));
      expect(parseYsNumber('75.42'), const Ok<int?, TextFormat>(7542));
      expect(parseYsNumber('100,00'), const Ok<int?, TextFormat>(10000));
    });

    test('requires exactly two decimals', () {
      for (final text in ['75,9', '75', '75,905']) {
        expect(
          parseYsNumber(text),
          const Err<int?, TextFormat>(TextFormat.ysNumber),
          reason: text,
        );
      }
    });
  });

  group('parseFormDate', () {
    final june13 = CalendarDate.tryFromParts(year: 2026, month: 6, day: 13);

    test('accepts the dotted, dashed and compact forms', () {
      for (final text in [
        '2026.06.13',
        '2026.6.13.',
        '2026-06-13',
        '20260613',
      ]) {
        expect(
          parseFormDate(text),
          Ok<CalendarDate?, TextFormat>(june13),
          reason: text,
        );
      }
    });

    test('rejects a day that does not exist', () {
      expect(
        parseFormDate('2026.02.30'),
        const Err<CalendarDate?, TextFormat>(TextFormat.date),
      );
    });

    test('rejects a two digit year', () {
      expect(
        parseFormDate('26.06.13'),
        const Err<CalendarDate?, TextFormat>(TextFormat.date),
      );
    });
  });

  group('parseClockTime', () {
    test('reads colon forms with optional seconds', () {
      expect(
        parseClockTime('10:00'),
        const Ok<ClockTime?, TextFormat>((hour: 10, minute: 0, second: 0)),
      );
      expect(
        parseClockTime('9:05:30'),
        const Ok<ClockTime?, TextFormat>((hour: 9, minute: 5, second: 30)),
      );
    });

    test('reads digit only forms', () {
      expect(
        parseClockTime('9'),
        const Ok<ClockTime?, TextFormat>((hour: 9, minute: 0, second: 0)),
      );
      expect(
        parseClockTime('930'),
        const Ok<ClockTime?, TextFormat>((hour: 9, minute: 30, second: 0)),
      );
      expect(
        parseClockTime('1000'),
        const Ok<ClockTime?, TextFormat>((hour: 10, minute: 0, second: 0)),
      );
      expect(
        parseClockTime('103015'),
        const Ok<ClockTime?, TextFormat>(
          (hour: 10, minute: 30, second: 15),
        ),
      );
    });

    test('rejects out of range values', () {
      for (final text in ['24:00', '10:60', '2400', '10:00:61', '1234567']) {
        expect(
          parseClockTime(text),
          const Err<ClockTime?, TextFormat>(TextFormat.time),
          reason: text,
        );
      }
    });
  });

  group('formatters', () {
    test('write the form shapes back', () {
      final date = CalendarDate.tryFromParts(year: 2026, month: 6, day: 3);
      expect(formatFormDate(date!), '2026.06.03');
      expect(formatClockTime((hour: 9, minute: 5, second: 0)), '09:05');
      expect(formatClockTime((hour: 9, minute: 5, second: 7)), '09:05:07');
    });

    test('drop needless zeros from decimals', () {
      expect(formatFormDecimal(10.2), '10,2');
      expect(formatFormDecimal(8), '8');
      expect(formatFormDecimal(100), '100');
      expect(formatFormDecimal(7.59999), '7,6');
    });
  });
}
