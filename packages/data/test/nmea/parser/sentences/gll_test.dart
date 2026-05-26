import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/gll.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = GllPositionDecoder();

  // A teljes, érvényes GLL mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt, hogy ne kelljen szintetikus sorhoz
  // checksumot számolni.
  const baseFields = [
    '4655.5324',
    'N',
    '01802.3321',
    'E',
    '083645',
    'A',
    'A',
  ];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence gll(List<String> fields) =>
      Sentence(talker: 'GP', type: 'GLL', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return gll(fields);
  }

  group('GllPositionDecoder', () {
    test('decodes a real GLL sentence into a position', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(
        parse(r'$GPGLL,4655.5324,N,01802.3321,E,083645,A,A*41'),
      );

      switch (decoded) {
        case null:
          fail('valid GLL sorra null decode');
        case DecodedPosition(:final position):
          expect(position.latitude, closeTo(46.92554, 0.0001));
          expect(position.longitude, closeTo(18.03887, 0.0001));
      }
    });

    test('returns null for an invalid status flag (V)', () {
      expect(decoder.decode(withField(5, 'V')), isNull);
    });

    test('returns null for too few fields', () {
      expect(decoder.decode(gll(['4655.5324', 'N', '01802.3321'])), isNull);
    });

    test('returns null for a non-numeric latitude field', () {
      expect(decoder.decode(withField(0, 'abc')), isNull);
    });

    test('returns null when the latitude is out of range', () {
      // 9955.5324 → 99.9° > 90 → a Coordinate.tryFromDegrees Err-t ad.
      expect(decoder.decode(withField(0, '9955.5324')), isNull);
    });

    test('returns null for an unknown hemisphere sign', () {
      expect(decoder.decode(withField(1, 'X')), isNull);
    });
  });
}
