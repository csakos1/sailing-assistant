import 'package:nmea_replay/src/logged_line.dart';
import 'package:test/test.dart';

void main() {
  group('parseLoggedLine', () {
    test('strips the prefix and keeps the full sentence from the marker', () {
      // Valós, prefixes sor a Vulcan-logból (checksum verifikálva).
      const line =
          '10:18:26.060 '
          r'$GPRMC,081822,A,4654.9159,N,01802.3576,E,2.4,341.0,240526,5.7,E,A*14';

      final result = parseLoggedLine(line);

      expect(result, isNotNull);
      if (result case final logged?) {
        expect(
          logged.sentence,
          equals(
            r'$GPRMC,081822,A,4654.9159,N,01802.3576,E,2.4,341.0,240526,5.7,E,A*14',
          ),
        );
      }
    });

    test('parses the wall-clock prefix to millisecond precision', () {
      const line =
          '10:18:26.067 '
          r'$IIHDG,39.4,,,5.7,E*1E';

      final result = parseLoggedLine(line);

      expect(result, isNotNull);
      if (result case final logged?) {
        expect(
          logged.timeOfDay,
          equals(
            const Duration(
              hours: 10,
              minutes: 18,
              seconds: 26,
              milliseconds: 67,
            ),
          ),
        );
      }
    });

    test('treats a ! encapsulation sentence as a sentence start', () {
      // Szintetikus sor: parseLoggedLine nem dekódol/checksumol, csak a
      // mondatkezdetet (! a $ mellett) teszteljük.
      const line = '11:02:05.500 !AIVDM,1,1,,A,15M,0*42';

      final result = parseLoggedLine(line);

      expect(result, isNotNull);
      if (result case final logged?) {
        expect(logged.sentence, startsWith('!AIVDM'));
      }
    });

    test('tolerates extra whitespace between prefix and sentence', () {
      const line =
          '10:18:26.067   '
          r'$GPVTG,341.0,T,335.3,M,2.4,N,4.5,K,A*24';

      final result = parseLoggedLine(line);

      expect(result, isNotNull);
      if (result case final logged?) {
        expect(logged.sentence, startsWith(r'$GPVTG'));
        expect(
          logged.timeOfDay,
          equals(
            const Duration(
              hours: 10,
              minutes: 18,
              seconds: 26,
              milliseconds: 67,
            ),
          ),
        );
      }
    });

    test('returns null for a line with no NMEA sentence', () {
      expect(parseLoggedLine('10:18:26.060 connected to 192.168.76.1'), isNull);
    });

    test('returns null for an empty line', () {
      expect(parseLoggedLine(''), isNull);
    });

    test('returns null for a whitespace-only line', () {
      expect(parseLoggedLine('   \t  '), isNull);
    });

    test('returns null for a sentence with no parseable prefix', () {
      // Van $, de nincs faliidő-prefix → az ütemezéshez nincs időbélyeg, skip.
      expect(parseLoggedLine(r'$GPRMC,081822,A,4654.9159,N*14'), isNull);
    });
  });
}
