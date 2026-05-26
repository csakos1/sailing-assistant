import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/vtg.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = VtgCogSogDecoder();

  // A teljes, érvényes VTG mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt, hogy ne kelljen szintetikus sorhoz
  // checksumot számolni.
  const baseFields = ['150.2', 'T', '144.5', 'M', '4.5', 'N', '8.2', 'K', 'A'];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence vtg(List<String> fields) =>
      Sentence(talker: 'GP', type: 'VTG', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return vtg(fields);
  }

  group('VtgCogSogDecoder', () {
    test('decodes a real VTG sentence (COG true, SOG)', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(
        parse(r'$GPVTG,150.2,T,144.5,M,4.5,N,8.2,K,A*2A'),
      );

      switch (decoded) {
        case null:
          fail('valid VTG sorra null decode');
        case DecodedCogSog(:final courseOverGround, :final speedOverGround):
          expect(courseOverGround.reference, BearingReference.trueNorth);
          expect(courseOverGround.degrees, closeTo(150.2, 0.001));
          // 4.5 csomó = 2.315 m/s.
          expect(speedOverGround.metersPerSecond, closeTo(2.315, 0.001));
      }
    });

    test('returns null for a wrong COG unit flag (not T)', () {
      expect(decoder.decode(withField(1, 'M')), isNull);
    });

    test('returns null for a wrong SOG unit flag (not N)', () {
      expect(decoder.decode(withField(5, 'K')), isNull);
    });

    test('returns null for a non-numeric COG field', () {
      expect(decoder.decode(withField(0, 'abc')), isNull);
    });

    test('returns null for a non-numeric SOG field', () {
      expect(decoder.decode(withField(4, 'xyz')), isNull);
    });

    test('returns null for a negative SOG (Speed validation fails)', () {
      // metersPerSecondFromKnots(-1) negatív -> Speed.tryFromMetersPerSecond Err.
      expect(decoder.decode(withField(4, '-1')), isNull);
    });

    test('returns null for too few fields', () {
      expect(decoder.decode(vtg(['150.2', 'T', '144.5', 'M'])), isNull);
    });
  });
}
