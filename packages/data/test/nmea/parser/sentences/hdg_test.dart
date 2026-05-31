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
    test('valós HDG → magnetic + true heading a variációból (E)', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05, Balaton): 5.7° E variáció.
      final decoded = decoder.decode(parse(r'$IIHDG,82.8,,,5.7,E*12'));

      switch (decoded) {
        case null:
          fail('valid HDG sorra null decode');
        case DecodedHeading(:final heading, :final headingTrue):
          expect(heading.reference, BearingReference.magneticNorth);
          expect(heading.degrees, closeTo(82.8, 0.001));
          expect(headingTrue, isNotNull);
          expect(headingTrue?.reference, BearingReference.trueNorth);
          // 82.8 + 5.7 = 88.5 (E → kelet, +).
          expect(headingTrue?.degrees, closeTo(88.5, 0.001));
      }
    });

    test('W variáció → true = magnetic − variation', () {
      final decoded = decoder.decode(hdg(const ['100', '', '', '5.0', 'W']));

      switch (decoded) {
        case null:
          fail('valid HDG-re null decode');
        case DecodedHeading(:final heading, :final headingTrue):
          expect(heading.degrees, closeTo(100, 0.001));
          // 100 − 5.0 = 95.0 (W → nyugat, −).
          expect(headingTrue?.degrees, closeTo(95, 0.001));
          expect(headingTrue?.reference, BearingReference.trueNorth);
      }
    });

    test('true heading 360 fölött körbefordul', () {
      final decoded = decoder.decode(hdg(const ['357', '', '', '5.0', 'E']));

      switch (decoded) {
        case null:
          fail('valid HDG-re null decode');
        case DecodedHeading(:final headingTrue):
          // 357 + 5.0 = 362 → 2.0 ([0, 360) wrap).
          expect(headingTrue?.degrees, closeTo(2, 0.001));
      }
    });

    test('hiányzó variáció-mezők → headingTrue null, magnetic megvan', () {
      final decoded = decoder.decode(hdg(const ['40.1', '', '']));

      switch (decoded) {
        case null:
          fail('valid magnetic headingre null decode');
        case DecodedHeading(:final heading, :final headingTrue):
          expect(heading.degrees, closeTo(40.1, 0.001));
          expect(headingTrue, isNull);
      }
    });

    test('üres variáció-érték → headingTrue null', () {
      final decoded = decoder.decode(hdg(const ['40.1', '', '', '', '']));

      switch (decoded) {
        case null:
          fail('valid magnetic headingre null decode');
        case DecodedHeading(:final headingTrue):
          expect(headingTrue, isNull);
      }
    });

    test('érvénytelen variáció-irány (nem E/W) → headingTrue null', () {
      final decoded = decoder.decode(hdg(const ['40.1', '', '', '5.7', 'X']));

      switch (decoded) {
        case null:
          fail('valid magnetic headingre null decode');
        case DecodedHeading(:final headingTrue):
          expect(headingTrue, isNull);
      }
    });

    test('nem-numerikus variáció-érték → headingTrue null', () {
      final decoded = decoder.decode(hdg(const ['40.1', '', '', 'abc', 'E']));

      switch (decoded) {
        case null:
          fail('valid magnetic headingre null decode');
        case DecodedHeading(:final headingTrue):
          expect(headingTrue, isNull);
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
