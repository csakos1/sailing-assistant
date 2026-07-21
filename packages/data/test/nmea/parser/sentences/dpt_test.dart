import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/dpt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = DptDepthDecoder();

  // A teljes, érvényes DPT mezőkészlet (address után): mélység, offset,
  // max range — az utolsó a valós dumpban mindig üres.
  const baseFields = ['3.0', '0.0', ''];

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence dpt(List<String> fields) =>
      Sentence(talker: 'SD', type: 'DPT', fields: fields, raw: '');

  Sentence withField(int index, String value) {
    final fields = [...baseFields];
    fields[index] = value;
    return dpt(fields);
  }

  group('DptDepthDecoder', () {
    test('decodes a real DPT sentence into depth', () {
      // Valós sor a Vulcan WiFi dumpból (2026-06, Tramontana-kupa).
      final decoded = decoder.decode(parse(r'$SDDPT,3.0,0.0,*78'));

      switch (decoded) {
        case null:
          fail('valid DPT sorra null decode');
        case DecodedDepth(:final depth, :final source):
          expect(depth.meters, closeTo(3, 0.001));
          expect(source, equals(DepthSource.dpt));
      }
    });

    test('ignores the offset field', () {
      // ADR 0031 A1-D4: az offsetet ([1]) nem olvassuk. Nem nulla offset
      // mellett is a nyers mélység-mező megy tovább.
      final decoded = decoder.decode(withField(1, '9.9'));

      switch (decoded) {
        case null:
          fail('az offset nem befolyásolhatja a dekódolást');
        case DecodedDepth(:final depth):
          expect(depth.meters, closeTo(3, 0.001));
      }
    });

    test('skips a non-numeric depth field', () {
      expect(decoder.decode(withField(0, 'zzz')), isNull);
    });

    test('skips an empty depth field', () {
      expect(decoder.decode(withField(0, '')), isNull);
    });

    test('skips a sentence without any field', () {
      expect(decoder.decode(dpt(const [])), isNull);
    });

    test('skips a negative depth', () {
      // Depth.tryFromMeters untrusted-validációja → Err → skip.
      expect(decoder.decode(withField(0, '-1.0')), isNull);
    });

    test('accepts a zero depth', () {
      // Ugyanaz a rögzített döntés, mint a DBT-nél: nincs padló a
      // dekóderben (a mért dumpban egyetlen 0,0 sincs).
      final decoded = decoder.decode(withField(0, '0.0'));

      switch (decoded) {
        case null:
          fail('a 0,0 m nem skip-eset');
        case DecodedDepth(:final depth):
          expect(depth.meters, equals(0));
      }
    });
  });
}
