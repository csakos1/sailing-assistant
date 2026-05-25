import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/rmc.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = RmcDecoder();

  // A teljes, érvényes RMC mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt, hogy ne kelljen szintetikus sorhoz
  // checksumot számolni.
  const baseFields = [
    '083645',
    'A',
    '4655.5323',
    'N',
    '01802.3322',
    'E',
    '4.5',
    '150.2',
    '240526',
    '5.7',
    'E',
    'A',
  ];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence rmc(List<String> fields) =>
      Sentence(talker: 'GP', type: 'RMC', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return rmc(fields);
  }

  group('RmcDecoder', () {
    test('decodes a real RMC sentence (position, COG/SOG, UTC)', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(
        parse(
          r'$GPRMC,083645,A,4655.5323,N,01802.3322,E,4.5,150.2,240526,5.7,E,A*1B',
        ),
      );

      switch (decoded) {
        case null:
          fail('valid RMC sorra null decode');
        case DecodedRmc(
          :final position,
          :final courseOverGround,
          :final speedOverGround,
          :final timestampUtc,
        ):
          expect(position.latitude, closeTo(46.92554, 0.0001));
          expect(position.longitude, closeTo(18.03887, 0.0001));
          expect(
            courseOverGround.reference,
            equals(BearingReference.trueNorth),
          );
          expect(courseOverGround.degrees, closeTo(150.2, 0.001));
          // 4.5 csomó = 2.315 m/s.
          expect(speedOverGround.metersPerSecond, closeTo(2.315, 0.001));
          expect(timestampUtc, equals(DateTime.utc(2026, 5, 24, 8, 36, 45)));
          expect(timestampUtc.isUtc, isTrue);
      }
    });

    test('returns null for an invalid status flag (V)', () {
      expect(decoder.decode(withField(1, 'V')), isNull);
    });

    test('returns null for too few fields', () {
      expect(decoder.decode(rmc(['083645', 'A', '4655.5323', 'N'])), isNull);
    });

    test('returns null when the latitude is out of range', () {
      // 9955.5323 → 99.9° > 90 → a Coordinate.tryFromDegrees Err-t ad.
      expect(decoder.decode(withField(2, '9955.5323')), isNull);
    });

    test('returns null for a non-numeric SOG', () {
      expect(decoder.decode(withField(6, 'x')), isNull);
    });

    test('returns null for an empty COG (stationary boat)', () {
      // v1 tudatos kompromisszum: álló hajónál az üres COG az egész RMC-t
      // skippeli; a pozíció a GGA/GLL-ből redundánsan jön (6.6).
      expect(decoder.decode(withField(7, '')), isNull);
    });
  });
}
