import 'package:domain/domain.dart';
import 'package:test/test.dart';

const _samplePosition = Coordinate(latitude: 46.946554, longitude: 18.012115);

/// Teszt-helper: alapértelmezett mezőkkel ad egy [SavedMark]-ot, a
/// felülírandó mezőt named paraméterrel cseréljük. Csak a default-tól
/// eltérő értéket adunk át, így a teszt a vizsgált különbséget mutatja,
/// és nem sül el a redundáns-argumentum lint.
SavedMark _sample({
  String name = 'VK',
  Coordinate position = _samplePosition,
  String sourceRaceName = 'Kedd esti',
  DateTime? savedAt,
}) {
  return SavedMark(
    name: name,
    position: position,
    sourceRaceName: sourceRaceName,
    savedAt: savedAt ?? DateTime.utc(2026, 6, 1, 10, 30),
  );
}

void main() {
  group('SavedMark', () {
    group('construction', () {
      test('a mezőket megőrzi', () {
        // ARRANGE & ACT
        final mark = _sample(
          name: 'BS',
          sourceRaceName: 'Szerda',
          savedAt: DateTime.utc(2026, 7, 2),
        );

        // ASSERT
        expect(mark.name, equals('BS'));
        expect(mark.position, equals(_samplePosition));
        expect(mark.sourceRaceName, equals('Szerda'));
        expect(mark.savedAt, equals(DateTime.utc(2026, 7, 2)));
      });

      test('üres név -> AssertionError', () {
        // Az assert runtime-ban fut (a lambda nem const-context).
        expect(() => _sample(name: ''), throwsA(isA<AssertionError>()));
      });

      test('üres forrás-verseny -> AssertionError', () {
        expect(
          () => _sample(sourceRaceName: ''),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality', () {
      test('azonos mezőkkel egyenlő (==/hashCode)', () {
        final a = _sample();
        final b = _sample();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('eltérő név -> nem egyenlő', () {
        expect(_sample(), isNot(equals(_sample(name: 'BS'))));
      });

      test('eltérő pozíció -> nem egyenlő', () {
        const other = Coordinate(latitude: 47, longitude: 18);
        expect(_sample(), isNot(equals(_sample(position: other))));
      });

      test('eltérő forrás-verseny -> nem egyenlő', () {
        expect(_sample(), isNot(equals(_sample(sourceRaceName: 'Más'))));
      });

      test('eltérő savedAt -> nem egyenlő', () {
        final other = DateTime.utc(2027);
        expect(_sample(), isNot(equals(_sample(savedAt: other))));
      });
    });
  });
}
