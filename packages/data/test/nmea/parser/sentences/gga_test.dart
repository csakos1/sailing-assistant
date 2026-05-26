import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/gga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = GgaPositionDecoder();

  // A teljes, érvényes GGA mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt, hogy ne kelljen szintetikus sorhoz
  // checksumot számolni.
  const baseFields = [
    '083645',
    '4655.5324',
    'N',
    '01802.3321',
    'E',
    '1',
    '12',
    '0.60',
    '66',
    'M',
    '41.2',
    'M',
    '',
    '',
  ];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence gga(List<String> fields) =>
      Sentence(talker: 'GN', type: 'GGA', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return gga(fields);
  }

  group('GgaPositionDecoder', () {
    test('decodes a real GGA sentence into a position', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(
        parse(
          r'$GNGGA,083645,4655.5324,N,01802.3321,E,1,12,0.60,66,M,41.2,M,,*46',
        ),
      );

      switch (decoded) {
        case null:
          fail('valid GGA sorra null decode');
        case DecodedPosition(:final position):
          expect(position.latitude, closeTo(46.92554, 0.0001));
          expect(position.longitude, closeTo(18.03887, 0.0001));
      }
    });

    test('returns null when there is no fix (fixQuality 0)', () {
      expect(decoder.decode(withField(5, '0')), isNull);
    });

    test('returns null for too few fields', () {
      expect(decoder.decode(gga(['083645', '4655.5324', 'N'])), isNull);
    });

    test('returns null for a non-numeric latitude field', () {
      expect(decoder.decode(withField(1, 'abc')), isNull);
    });

    test('returns null when the latitude is out of range', () {
      // 9955.5324 → 99.9° > 90 → a Coordinate.tryFromDegrees Err-t ad.
      expect(decoder.decode(withField(1, '9955.5324')), isNull);
    });

    test('returns null for an unknown hemisphere sign', () {
      expect(decoder.decode(withField(2, 'X')), isNull);
    });
  });
}
