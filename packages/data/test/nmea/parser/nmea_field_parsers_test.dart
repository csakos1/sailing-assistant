import 'package:data/src/nmea/parser/nmea_field_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decimalDegreesFromNmea', () {
    test('ddmm.mmmm + N → pozitív decimális fok', () {
      // 4655.5323,N → 46 + 55.5323/60.
      expect(
        decimalDegreesFromNmea('4655.5323', 'N'),
        closeTo(46.92554, 0.0001),
      );
    });

    test('dddmm.mmmm + E → pozitív decimális fok', () {
      expect(
        decimalDegreesFromNmea('01802.3322', 'E'),
        closeTo(18.03887, 0.0001),
      );
    });

    test('déli félteke (S) → negatív', () {
      expect(
        decimalDegreesFromNmea('4655.5323', 'S'),
        closeTo(-46.92554, 0.0001),
      );
    });

    test('nyugati félteke (W) → negatív', () {
      expect(
        decimalDegreesFromNmea('01802.3322', 'W'),
        closeTo(-18.03887, 0.0001),
      );
    });

    test('ismeretlen hemiszféra-jel → null', () {
      expect(decimalDegreesFromNmea('4655.5323', 'X'), isNull);
    });

    test('nem-numerikus érték → null', () {
      expect(decimalDegreesFromNmea('abc', 'N'), isNull);
    });

    test('NaN literál → null (a .floor() crash helyett)', () {
      expect(decimalDegreesFromNmea('NaN', 'N'), isNull);
    });

    test('üres mező → null', () {
      expect(decimalDegreesFromNmea('', 'N'), isNull);
    });
  });

  group('utcDateTimeFromNmea', () {
    test('ddmmyy + hhmmss → DateTime.utc', () {
      // 240526 + 083645 → 2026-05-24 08:36:45 UTC.
      final dt = utcDateTimeFromNmea('240526', '083645');

      expect(dt, equals(DateTime.utc(2026, 5, 24, 8, 36, 45)));
      expect(dt?.isUtc, isTrue);
    });

    test('rossz dátum-hossz → null', () {
      expect(utcDateTimeFromNmea('2405', '083645'), isNull);
    });

    test('tizedmásodperces idő (.ss) → null', () {
      expect(utcDateTimeFromNmea('240526', '083645.50'), isNull);
    });

    test('nem-numerikus mező → null', () {
      expect(utcDateTimeFromNmea('2405XX', '083645'), isNull);
    });
  });
}
