import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/hdg.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = HdgHeadingDecoder();

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  Sentence hdg(List<String> fields) =>
      Sentence(talker: 'II', type: 'HDG', fields: fields, raw: '');

  group('HdgHeadingDecoder', () {
    test('decodes a real HDG sentence into a magnetic heading', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton).
      final decoded = decoder.decode(parse(r'$IIHDG,82.8,,,5.7,E*12'));

      switch (decoded) {
        case null:
          fail('valid HDG sorra null decode');
        case DecodedHeading(:final heading):
          expect(heading.reference, BearingReference.magneticNorth);
          expect(heading.degrees, closeTo(82.8, 0.001));
      }
    });

    test('returns null for an empty field list', () {
      expect(decoder.decode(hdg(const [])), isNull);
    });

    test('returns null for a non-numeric heading field', () {
      expect(decoder.decode(hdg(const ['abc', '', '', '5.7', 'E'])), isNull);
    });

    test('returns null for a non-finite heading (NaN)', () {
      // double.tryParse('NaN') NaN-t ad → a Bearing.tryFromDegrees Err-t ad.
      expect(decoder.decode(hdg(const ['NaN', '', '', '5.7', 'E'])), isNull);
    });
  });
}
