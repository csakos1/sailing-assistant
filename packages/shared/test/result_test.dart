import 'package:shared/shared.dart';
import 'package:test/test.dart';

void main() {
  group('Result<T, E>', () {
    group('Ok', () {
      test('a value mező a konstruktorban megadott értéket hordozza', () {
        const result = Ok<int, String>(42);

        expect(result.value, equals(42));
      });

      test(
        'két Ok ugyanazzal a value-val egyenlő, és a hashCode is egyezik',
        () {
          const a = Ok<int, String>(42);
          const b = Ok<int, String>(42);

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('két Ok különböző value-val nem egyenlő', () {
        const a = Ok<int, String>(42);
        const b = Ok<int, String>(43);

        expect(a, isNot(equals(b)));
      });

      test('toString a value-t reprezentálja', () {
        const result = Ok<int, String>(42);

        expect(result.toString(), equals('Ok(42)'));
      });
    });

    group('Err', () {
      test('az error mező a konstruktorban megadott hibát hordozza', () {
        const result = Err<int, String>('invalid input');

        expect(result.error, equals('invalid input'));
      });

      test(
        'két Err ugyanazzal a hibával egyenlő, és a hashCode is egyezik',
        () {
          const a = Err<int, String>('bad');
          const b = Err<int, String>('bad');

          expect(a, equals(b));
          expect(a.hashCode, equals(b.hashCode));
        },
      );

      test('két Err különböző hibával nem egyenlő', () {
        const a = Err<int, String>('bad');
        const b = Err<int, String>('worse');

        expect(a, isNot(equals(b)));
      });

      test('toString az error-t reprezentálja', () {
        const result = Err<int, String>('bad');

        expect(result.toString(), equals('Err(bad)'));
      });
    });

    group('Ok és Err megkülönböztetés', () {
      test(
        'Ok és Err nem egyenlő, akkor sem ha ugyanazt hordozzák típus szerint',
        () {
          const ok = Ok<int, int>(42);
          const err = Err<int, int>(42);

          expect(ok, isNot(equals(err)));
        },
      );
    });

    group('pattern matching', () {
      test(
        'a switch expression exhaustive — mindkét ágat kötelező kezelni',
        () {
          Result<int, String> compute({required bool succeeds}) =>
              succeeds ? const Ok(42) : const Err('failed');

          // Az Ok ág
          final okMessage = switch (compute(succeeds: true)) {
            Ok(value: final v) => 'got $v',
            Err(error: final e) => 'failed: $e',
          };
          expect(okMessage, equals('got 42'));

          // Az Err ág
          final errMessage = switch (compute(succeeds: false)) {
            Ok(value: final v) => 'got $v',
            Err(error: final e) => 'failed: $e',
          };
          expect(errMessage, equals('failed: failed'));
        },
      );
    });
  });
}
