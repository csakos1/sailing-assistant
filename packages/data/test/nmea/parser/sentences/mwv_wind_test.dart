import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/mwv_wind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = MwvWindDecoder();

  // A két valós sort a teljes láncon (sor → Sentence → DecodedWind)
  // ellenőrizzük; az élesítő esetek közvetlenül Sentence-t építenek, hogy
  // ne kelljen szintetikus sorhoz checksumot számolni.
  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  group('MwvWindDecoder', () {
    test('decodes a real apparent-wind (R) sentence', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05).
      final decoded = decoder.decode(parse(r'$WIMWV,54.0,R,4.0,N,A*16'));

      switch (decoded) {
        case null:
          fail('valid MWV-R sorra null decode');
        case DecodedWind(:final reference, :final angle, :final speed):
          expect(reference, equals(WindReference.apparent));
          expect(angle.degrees, closeTo(54, 0.001));
          // 4.0 csomó ≈ 2.0578 m/s.
          expect(speed.metersPerSecond, closeTo(2.0578, 0.001));
      }
    });

    test('decodes a real true-wind (T) sentence', () {
      final decoded = decoder.decode(parse(r'$WIMWV,122.5,T,3.9,N,A*2B'));

      switch (decoded) {
        case null:
          fail('valid MWV-T sorra null decode');
        case DecodedWind(:final reference, :final angle, :final speed):
          expect(reference, equals(WindReference.true_));
          expect(angle.degrees, closeTo(122.5, 0.001));
          // 3.9 csomó ≈ 2.0063 m/s.
          expect(speed.metersPerSecond, closeTo(2.0063, 0.001));
      }
    });

    test('normalizes a wire angle above 180 into signed [-180, 180)', () {
      // 270° az orrtól → bal oldal, signed -90°.
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['270.0', 'R', '4.0', 'N', 'A'],
        raw: r'$WIMWV,270.0,R,4.0,N,A',
      );

      switch (decoder.decode(s)) {
        case null:
          fail('270°-os MWV-R sorra null decode');
        case DecodedWind(:final angle):
          expect(angle.degrees, closeTo(-90, 0.001));
      }
    });

    test('returns null for an invalid status flag (V)', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['54.0', 'R', '4.0', 'N', 'V'],
        raw: r'$WIMWV,54.0,R,4.0,N,V',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for an unknown reference', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['54.0', 'Z', '4.0', 'N', 'A'],
        raw: r'$WIMWV,54.0,Z,4.0,N,A',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for an unknown speed unit', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['54.0', 'R', '4.0', 'X', 'A'],
        raw: r'$WIMWV,54.0,R,4.0,X,A',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for a non-numeric angle', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['abc', 'R', '4.0', 'N', 'A'],
        raw: r'$WIMWV,abc,R,4.0,N,A',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for too few fields', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWV',
        fields: ['54.0', 'R', '4.0'],
        raw: r'$WIMWV,54.0,R,4.0',
      );

      expect(decoder.decode(s), isNull);
    });
  });
}
