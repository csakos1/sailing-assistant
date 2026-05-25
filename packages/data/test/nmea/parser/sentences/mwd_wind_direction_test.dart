import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/nmea0183_line_parser.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentences/mwd_wind_direction.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  const parser = Nmea0183LineParser();
  const decoder = MwdWindDirectionDecoder();

  Sentence parse(String raw) => switch (parser.parse(raw)) {
    Ok(value: final s) => s,
    Err() => fail('valid soron nem várt Err: $raw'),
  };

  group('MwdWindDirectionDecoder', () {
    test('decodes a real MWD sentence (true direction + m/s speed)', () {
      // Valós sor a Vulcan WiFi dumpból (2026-05).
      final s = parse(r'$WIMWD,211.2,T,205.4,M,3.9,N,2.0,M*51');
      final decoded = decoder.decode(s);

      switch (decoded) {
        case null:
          fail('valid MWD sorra null decode');
        case DecodedWindDirection(:final direction, :final speed):
          expect(direction.degrees, closeTo(211.2, 0.001));
          expect(direction.reference, equals(BearingReference.trueNorth));
          expect(speed.metersPerSecond, closeTo(2, 0.001));
      }
    });

    test('returns null when the true-direction marker is wrong', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWD',
        fields: ['211.2', 'X', '205.4', 'M', '3.9', 'N', '2.0', 'M'],
        raw: r'$WIMWD,211.2,X,205.4,M,3.9,N,2.0,M',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null when the m/s unit marker is missing', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWD',
        fields: ['211.2', 'T', '205.4', 'M', '3.9', 'N', '2.0', 'X'],
        raw: r'$WIMWD,211.2,T,205.4,M,3.9,N,2.0,X',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for a non-numeric direction', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWD',
        fields: ['abc', 'T', '205.4', 'M', '3.9', 'N', '2.0', 'M'],
        raw: r'$WIMWD,abc,T,205.4,M,3.9,N,2.0,M',
      );

      expect(decoder.decode(s), isNull);
    });

    test('returns null for too few fields', () {
      const s = Sentence(
        talker: 'WI',
        type: 'MWD',
        fields: ['211.2', 'T', '205.4', 'M', '3.9', 'N'],
        raw: r'$WIMWD,211.2,T,205.4,M,3.9,N',
      );

      expect(decoder.decode(s), isNull);
    });
  });
}
