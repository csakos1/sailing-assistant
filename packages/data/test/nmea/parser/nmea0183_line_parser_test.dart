import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/parse_error.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();

  group('Nmea0183LineParser', () {
    group('valid sentences', () {
      test('parses a real MWV sentence into talker, type and fields', () {
        // Valós sor a Vulcan WiFi dumpból (2026-05).
        const raw = r'$WIMWV,90.1,T,8.1,N,A*14';

        final result = parser.parse(raw);

        switch (result) {
          case Ok(value: final s):
            expect(s.talker, equals('WI'));
            expect(s.type, equals('MWV'));
            expect(s.fields, equals(['90.1', 'T', '8.1', 'N', 'A']));
            expect(s.raw, equals(raw));
          case Err():
            fail('valid soron nem várt Err');
        }
      });

      test('parses a real RMC sentence with twelve data fields', () {
        const raw =
            r'$GPRMC,083645,A,4655.5323,N,01802.3322,E,4.5,150.2,240526,5.7,E,A*1B';

        final result = parser.parse(raw);

        switch (result) {
          case Ok(value: final s):
            expect(s.talker, equals('GP'));
            expect(s.type, equals('RMC'));
            expect(s.fields.length, equals(12));
            expect(s.fields.first, equals('083645'));
            expect(s.fields.last, equals('A'));
          case Err():
            fail('valid RMC soron nem várt Err');
        }
      });

      test('accepts lowercase hex in the checksum', () {
        // A valós '*2A' checksum kisbetűsen ('2a') is érvényes kell legyen.
        const raw = r'$GPVTG,150.2,T,144.5,M,4.5,N,8.2,K,A*2a';

        expect(parser.parse(raw), isA<Ok<Sentence, ParseError>>());
      });
    });

    group('error cases', () {
      test('empty line maps to ParseError.empty', () {
        expect(
          parser.parse(''),
          const Err<Sentence, ParseError>(ParseError.empty),
        );
      });

      test('whitespace-only line maps to ParseError.empty', () {
        expect(
          parser.parse('   \r\n'),
          const Err<Sentence, ParseError>(ParseError.empty),
        );
      });

      test('missing start delimiter maps to ParseError.malformed', () {
        expect(
          parser.parse('WIMWV,90.1,T,8.1,N,A*14'),
          const Err<Sentence, ParseError>(ParseError.malformed),
        );
      });

      test('missing checksum block maps to ParseError.malformed', () {
        expect(
          parser.parse(r'$WIMWV,90.1,T,8.1,N,A'),
          const Err<Sentence, ParseError>(ParseError.malformed),
        );
      });

      test('non-hex checksum maps to ParseError.malformed', () {
        expect(
          parser.parse(r'$WIMWV,90.1,T,8.1,N,A*1G'),
          const Err<Sentence, ParseError>(ParseError.malformed),
        );
      });

      test('wrong checksum maps to ParseError.checksumMismatch', () {
        // A helyes checksum *14; a *15 eltérést kell jeleznie.
        expect(
          parser.parse(r'$WIMWV,90.1,T,8.1,N,A*15'),
          const Err<Sentence, ParseError>(ParseError.checksumMismatch),
        );
      });

      test('too-short address token maps to ParseError.malformed', () {
        // 'XYZ' háromkarakteres address (< 5), de helyes *5B checksummal,
        // hogy ne a checksum-ág nyelje el — a rövid address miatt malformed.
        expect(
          parser.parse(r'$XYZ*5B'),
          const Err<Sentence, ParseError>(ParseError.malformed),
        );
      });
    });
  });
}
