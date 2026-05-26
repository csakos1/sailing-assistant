import 'package:data/src/nmea/parser/decoded_sentence.dart';
import 'package:data/src/nmea/parser/sentence.dart';
import 'package:data/src/nmea/parser/sentence_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

// Valós, érvényes mezőkészletek a megfelelő dekóder-tesztekből (a hosszú,
// többször használt kettő kiemelve).
const _ggaFields = [
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
const _rmcFields = [
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

void main() {
  const decoder = SentenceDecoder();

  Sentence sentence(
    String type,
    List<String> fields, {
    String talker = 'GP',
  }) => Sentence(talker: talker, type: type, fields: fields, raw: '');

  group('SentenceDecoder', () {
    // type → (érvényes mezők, várt leaf): minden type a saját dekóderének
    // leaf-jére route-ol.
    final routes = <String, (List<String>, Matcher)>{
      'MWV': (const ['54.0', 'R', '4.0', 'N', 'A'], isA<DecodedWind>()),
      'MWD': (
        const ['211.2', 'T', '205.4', 'M', '3.9', 'N', '2.0', 'M'],
        isA<DecodedWindDirection>(),
      ),
      'RMC': (_rmcFields, isA<DecodedRmc>()),
      'VTG': (
        const ['150.2', 'T', '144.5', 'M', '4.5', 'N', '8.2', 'K', 'A'],
        isA<DecodedCogSog>(),
      ),
      'GGA': (_ggaFields, isA<DecodedPosition>()),
      'GLL': (
        const ['4655.5324', 'N', '01802.3321', 'E', '083645', 'A', 'A'],
        isA<DecodedPosition>(),
      ),
      'HDG': (const ['82.8', '', '', '5.7', 'E'], isA<DecodedHeading>()),
      'VHW': (
        const ['88.5', 'T', '82.8', 'M', '4.6', 'N', '8.6', 'K'],
        isA<DecodedSpeed>(),
      ),
    };

    for (final entry in routes.entries) {
      final type = entry.key;
      final (fields, matcher) = entry.value;
      test('routes $type to its decoder leaf', () {
        expect(decoder.decode(sentence(type, fields)), matcher);
      });
    }

    test('returns null for an unsupported type', () {
      // GSV a v1 skip-listáján van; ismeretlen type → null.
      expect(decoder.decode(sentence('GSV', const ['1', '1', '12'])), isNull);
    });

    test('routes on type regardless of talker', () {
      // Ugyanaz a GGA mezőkészlet GN és egy szokatlan talkerrel is a
      // pozícióra route-ol — a dispatcher a talkert nem nézi.
      expect(
        decoder.decode(sentence('GGA', _ggaFields, talker: 'GN')),
        isA<DecodedPosition>(),
      );
      expect(
        decoder.decode(sentence('GGA', _ggaFields, talker: 'ZZ')),
        isA<DecodedPosition>(),
      );
    });

    test('propagates a decoder skip as null', () {
      // A type támogatott, de a dekóder skippel: RMC invalid status (V). A
      // dispatcher a dekóder null-ját változtatás nélkül továbbadja.
      final fields = [..._rmcFields]..[1] = 'V';
      expect(decoder.decode(sentence('RMC', fields)), isNull);
    });
  });
}
