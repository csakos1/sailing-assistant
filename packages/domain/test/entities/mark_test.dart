import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Mark', () {
    // Közös test-fixture-ök. A samplePosition const-elhető,
    // a sampleTime nem (DateTime-nek nincs const konstruktora).
    const samplePosition = Coordinate(latitude: 46.5, longitude: 18);
    final sampleTime = DateTime(2025, 6, 1, 12);

    group('construction', () {
      test('érvényes paraméterekkel létrejön', () {
        const mark = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
        );

        expect(mark.sequence, equals(1));
        expect(mark.name, equals('Z1'));
        expect(mark.position, equals(samplePosition));
        expect(mark.roundedAt, isNull);
      });

      test('roundedAt opcionálisan átadható', () {
        // Nem const: a sampleTime runtime-érték.
        final mark = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
          roundedAt: sampleTime,
        );

        expect(mark.roundedAt, equals(sampleTime));
      });

      test('sequence < 1 -> AssertionError', () {
        // Az assert runtime-ban fut le (a lambda nem const-context),
        // ezért nem const Mark itt.
        expect(
          () => Mark(sequence: 0, name: 'Z1', position: samplePosition),
          throwsA(isA<AssertionError>()),
        );
      });

      test('üres név -> AssertionError', () {
        expect(
          () => Mark(sequence: 1, name: '', position: samplePosition),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality', () {
      test('két ugyanolyan értékű Mark egyenlő', () {
        const a = Mark(sequence: 1, name: 'Z1', position: samplePosition);
        const b = Mark(sequence: 1, name: 'Z1', position: samplePosition);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző sequence -> nem egyenlő', () {
        const a = Mark(sequence: 1, name: 'Z1', position: samplePosition);
        const b = Mark(sequence: 2, name: 'Z1', position: samplePosition);

        expect(a, isNot(equals(b)));
      });

      test('különböző name -> nem egyenlő', () {
        const a = Mark(sequence: 1, name: 'Z1', position: samplePosition);
        const b = Mark(sequence: 1, name: 'Z2', position: samplePosition);

        expect(a, isNot(equals(b)));
      });

      test('különböző position -> nem egyenlő', () {
        const other = Coordinate(latitude: 47, longitude: 18);
        const a = Mark(sequence: 1, name: 'Z1', position: samplePosition);
        const b = Mark(sequence: 1, name: 'Z1', position: other);

        expect(a, isNot(equals(b)));
      });

      test('különböző roundedAt -> nem egyenlő', () {
        const a = Mark(sequence: 1, name: 'Z1', position: samplePosition);
        final b = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
          roundedAt: sampleTime,
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('paraméter nélkül ugyanazt adja vissza', () {
        const original = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
        );

        expect(original.copyWith(), equals(original));
      });

      test('csak a megadott mezőt cseréli', () {
        const original = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
        );

        final renamed = original.copyWith(name: 'Tihany');

        expect(renamed.name, equals('Tihany'));
        expect(renamed.sequence, equals(original.sequence));
        expect(renamed.position, equals(original.position));
        expect(renamed.roundedAt, isNull);
      });

      test('roundedAt-ot explicit null nem törli a meglévő értéket', () {
        // A simple-copyWith szándékos viselkedése: null = "ne változtass".
        // A monotonicitás invariánsát ez a forma kódolja.
        final rounded = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
          roundedAt: sampleTime,
        );

        final stillRounded = rounded.copyWith();

        expect(stillRounded.roundedAt, equals(sampleTime));
      });
    });

    group('markedAsRounded', () {
      test('roundedAt-ot a megadott időpontra állítja', () {
        const original = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
        );

        final rounded = original.markedAsRounded(at: sampleTime);

        expect(rounded.roundedAt, equals(sampleTime));
        expect(rounded.sequence, equals(original.sequence));
        expect(rounded.name, equals(original.name));
        expect(rounded.position, equals(original.position));
      });

      test('már körözött Mark-ra hívva -> AssertionError', () {
        final rounded = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
          roundedAt: sampleTime,
        );
        final later = sampleTime.add(const Duration(hours: 1));

        expect(
          () => rounded.markedAsRounded(at: later),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('toString', () {
      test('tartalmazza a Mark típusnevet és a mezőket', () {
        const mark = Mark(
          sequence: 1,
          name: 'Z1',
          position: samplePosition,
        );

        final s = mark.toString();
        expect(s, contains('Mark'));
        expect(s, contains('Z1'));
      });
    });
  });
}
