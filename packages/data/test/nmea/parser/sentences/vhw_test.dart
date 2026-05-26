import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/vhw.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = VhwSpeedDecoder();

  // A teljes, érvényes VHW mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt.
  const baseFields = ['88.5', 'T', '82.8', 'M', '4.6', 'N', '8.6', 'K'];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence vhw(List<String> fields) =>
      Sentence(talker: 'SD', type: 'VHW', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return vhw(fields);
  }

  group('VhwSpeedDecoder', () {
    test('decodes a real VHW sentence into speed through water', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(
        parse(r'$SDVHW,88.5,T,82.8,M,4.6,N,8.6,K*49'),
      );

      switch (decoded) {
        case null:
          fail('valid VHW sorra null decode');
        case DecodedSpeed(:final speedThroughWater):
          // 4.6 csomó = 2.3664 m/s.
          expect(speedThroughWater.metersPerSecond, closeTo(2.3664, 0.001));
      }
    });

    test('ignores the unused heading fields and still decodes STW', () {
      // A v1 csak az STW-t ([4]) olvassa; a heading-mezők ([0], [2]) lehetnek
      // garbage, a dekódolásnak akkor is sikerülnie kell.
      final decoded = decoder.decode(withField(0, 'zzz'));

      switch (decoded) {
        case null:
          fail('a használt STW-mező valid, mégis null decode');
        case DecodedSpeed(:final speedThroughWater):
          expect(speedThroughWater.metersPerSecond, closeTo(2.3664, 0.001));
      }
    });

    test('returns null for a wrong STW unit flag (not N)', () {
      expect(decoder.decode(withField(5, 'K')), isNull);
    });

    test('returns null for a non-numeric STW field', () {
      expect(decoder.decode(withField(4, 'xyz')), isNull);
    });

    test('returns null for a negative STW (Speed validation fails)', () {
      // metersPerSecondFromKnots(-1) negatív -> Speed.tryFromMetersPerSecond Err.
      expect(decoder.decode(withField(4, '-1')), isNull);
    });

    test('returns null for too few fields', () {
      expect(
        decoder.decode(vhw(const ['88.5', 'T', '82.8', 'M', '4.6'])),
        isNull,
      );
    });
  });
}
