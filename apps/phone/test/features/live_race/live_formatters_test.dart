import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/live_race/live_formatters.dart';

void main() {
  group('formatAngleMagnitude', () {
    test('renders magnitude without sign, rounded', () {
      expect(formatAngleMagnitude(const Angle(degrees: 32.4)), '32°');
      expect(formatAngleMagnitude(const Angle(degrees: -46.6)), '47°');
    });

    test('null -> placeholder', () {
      expect(formatAngleMagnitude(null), missingValue);
    });
  });

  group('formatBearing', () {
    test('pads to three digits', () {
      expect(formatBearing(const Bearing.true_(95.4)), '095°');
      expect(formatBearing(const Bearing.true_(7)), '007°');
    });

    test('rounding up to 360 wraps to 000', () {
      expect(formatBearing(const Bearing.true_(359.7)), '000°');
    });

    test('null -> placeholder', () {
      expect(formatBearing(null), missingValue);
    });
  });

  group('formatDistance', () {
    test('under 1000 m -> whole metres', () {
      expect(formatDistance(const Distance(meters: 450)), '450 m');
    });

    test('1000 m and above -> two-decimal km with a decimal comma', () {
      expect(formatDistance(const Distance(meters: 1000)), '1,00 km');
      expect(formatDistance(const Distance(meters: 1850)), '1,85 km');
    });

    test('null -> placeholder', () {
      expect(formatDistance(null), missingValue);
    });
  });

  group('formatEta', () {
    test('under an hour -> mm:ss', () {
      expect(
        formatEta(const Duration(minutes: 7, seconds: 32), minutesUnit: 'perc'),
        '07:32',
      );
      expect(formatEta(Duration.zero, minutesUnit: 'perc'), '00:00');
      expect(
        formatEta(const Duration(seconds: 3599), minutesUnit: 'perc'),
        '59:59',
      );
    });

    test('an hour and above -> whole minutes with unit', () {
      expect(
        formatEta(const Duration(hours: 1), minutesUnit: 'perc'),
        '60 perc',
      );
      expect(
        formatEta(const Duration(minutes: 83), minutesUnit: 'perc'),
        '83 perc',
      );
    });

    test('null -> placeholder', () {
      expect(formatEta(null, minutesUnit: 'perc'), missingValue);
    });
  });

  group('formatInstrumentTime', () {
    test('renders HH:mm:ss', () {
      // Local DateTime-ot adunk: a toLocal() egy local értéken identitás,
      // így a teszt időzóna-független marad (a formázást, nem a TZ-váltást
      // ellenőrzi).
      expect(
        formatInstrumentTime(DateTime(2026, 5, 29, 14, 32, 7)),
        '14:32:07',
      );
      expect(
        formatInstrumentTime(DateTime(2026, 5, 29, 9, 5, 3)),
        '09:05:03',
      );
    });

    test('null -> placeholder', () {
      expect(formatInstrumentTime(null), missingTime);
    });
  });

  group('formatVmgLive', () {
    test('one decimal, with a decimal comma', () {
      expect(formatVmgLive(5.84), '5,8');
      expect(formatVmgLive(6), '6,0');
    });

    test('keeps the sign of a losing VMG', () {
      expect(formatVmgLive(-1.4), '-1,4');
    });

    test('null -> placeholder', () {
      expect(formatVmgLive(null), missingValue);
    });
  });

  group('formatVmgTarget', () {
    test('one decimal, with a decimal comma', () {
      expect(formatVmgTarget(6.24), '6,2');
    });

    // A null itt nem hianyzo adat: a kisero sor ilyenkor elmarad a
    // cellabol, ezert a formazo sem gondolatjelet ad.
    test('null -> null, so the caller can drop the support row', () {
      expect(formatVmgTarget(null), isNull);
    });
  });
}
