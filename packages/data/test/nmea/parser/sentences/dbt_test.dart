import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/dbt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = DbtDepthDecoder();

  // A teljes, érvényes DBT mezőkészlet (address után); az élesítő esetek
  // ebből írnak felül egy mezőt.
  const baseFields = ['9.8', 'f', '3.0', 'M', '1.6', 'F'];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence dbt(List<String> fields) =>
      Sentence(talker: 'SD', type: 'DBT', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return dbt(fields);
  }

  group('DbtDepthDecoder', () {
    test('decodes a real DBT sentence into depth below transducer', () {
      // Valós sor a Vulcan WiFi dumpból (2026-06, Tramontana-kupa).
      final decoded = decoder.decode(parse(r'$SDDBT,9.8,f,3.0,M,1.6,F*03'));

      switch (decoded) {
        case null:
          fail('valid DBT sorra null decode');
        case DecodedDepth(:final depth, :final source):
          // A méter-mező ([2]) megy, a láb/öl redundáns.
          expect(depth.meters, closeTo(3, 0.001));
          expect(source, equals(DepthSource.dbt));
      }
    });

    test('ignores the unused feet and fathom fields', () {
      // A v1 csak a méter-mezőt ([2]) olvassa; a láb ([0]) és az öl ([4])
      // lehet garbage, a dekódolásnak akkor is sikerülnie kell.
      final decoded = decoder.decode(withField(0, 'zzz'));

      switch (decoded) {
        case null:
          fail('a használt méter-mező valid, mégis null decode');
        case DecodedDepth(:final depth):
          expect(depth.meters, closeTo(3, 0.001));
      }
    });

    test('skips when the unit marker is not M', () {
      // Az egységjelölő ([3]) védi meg attól, hogy más mezőkiosztású
      // mondatból véletlenül lábat olvassunk méterként.
      expect(decoder.decode(withField(3, 'F')), isNull);
    });

    test('skips a non-numeric depth field', () {
      expect(decoder.decode(withField(2, 'zzz')), isNull);
    });

    test('skips an empty depth field', () {
      // A jeladó a visszhang elvesztésekor üres mezőt is adhat.
      expect(decoder.decode(withField(2, '')), isNull);
    });

    test('skips a truncated sentence', () {
      // A [3]-as egységjelölőig kell mező; ennél rövidebb nem használható.
      expect(decoder.decode(dbt(const ['9.8', 'f', '3.0'])), isNull);
    });

    test('skips a negative depth', () {
      // Depth.tryFromMeters untrusted-validációja → Err → skip.
      expect(decoder.decode(withField(2, '-1.0')), isNull);
    });

    test('accepts a zero depth', () {
      // Rögzített döntés: NINCS plauzibilitás-padló a dekóderben. A mért
      // 19 327 DBT mintában egyetlen 0,0 sincs, tehát bizonyíték nélkül
      // szűrnénk; ha a jeladó-csere után előfordulna, külön ADR-pont lesz.
      final decoded = decoder.decode(withField(2, '0.0'));

      switch (decoded) {
        case null:
          fail('a 0,0 m nem skip-eset');
        case DecodedDepth(:final depth):
          expect(depth.meters, equals(0));
      }
    });
  });
}
