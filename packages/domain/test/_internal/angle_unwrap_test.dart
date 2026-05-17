import 'package:domain/src/_internal/angle_unwrap.dart';
import 'package:test/test.dart';

void main() {
  group('unwrapAngles', () {
    group('trivial cases', () {
      test('empty input → empty output', () {
        expect(unwrapAngles(<double>[]), isEmpty);
      });

      test('single-element input → unchanged', () {
        expect(unwrapAngles(<double>[42]), equals(<double>[42]));
      });

      test('two identical samples → unchanged (no wrap)', () {
        expect(
          unwrapAngles(<double>[180, 180]),
          equals(<double>[180, 180]),
        );
      });
    });

    group('non-wrapping sequences', () {
      test('monotonic increasing within range → unchanged', () {
        expect(
          unwrapAngles(<double>[10, 20, 30, 40]),
          equals(<double>[10, 20, 30, 40]),
        );
      });

      test('monotonic decreasing within range → unchanged', () {
        expect(
          unwrapAngles(<double>[100, 90, 80, 70]),
          equals(<double>[100, 90, 80, 70]),
        );
      });
    });

    group('wrap-around detection', () {
      test('clockwise wrap 350 → 10 unwraps to 350, 370 (+20°/step)', () {
        expect(
          unwrapAngles(<double>[350, 10]),
          equals(<double>[350, 370]),
        );
      });

      test('counterclockwise wrap 10 → 350 unwraps to 10, -10 (-20°/step)', () {
        expect(
          unwrapAngles(<double>[10, 350]),
          equals(<double>[10, -10]),
        );
      });

      test('multiple wraps in same direction accumulate offset', () {
        // 350 → 10 → 30 → 50: clockwise drift +20°/sample
        expect(
          unwrapAngles(<double>[350, 10, 30, 50]),
          equals(<double>[350, 370, 390, 410]),
        );
      });

      test('back-and-forth: wrap then unwrap-back', () {
        // 350 → 10 → 350: clockwise wrap majd counterclockwise wrap-back
        expect(
          unwrapAngles(<double>[350, 10, 350]),
          equals(<double>[350, 370, 350]),
        );
      });
    });

    group('180° ambivalencia (szigorú küszöb)', () {
      test('exact +180° step is NOT treated as wrap', () {
        // raw = +180 nem > 180, így nem csökkenti az offsetet.
        expect(
          unwrapAngles(<double>[0, 180]),
          equals(<double>[0, 180]),
        );
      });

      test('exact -180° step is NOT treated as wrap', () {
        // raw = -180 nem < -180, így nem növeli az offsetet.
        expect(
          unwrapAngles(<double>[180, 0]),
          equals(<double>[180, 0]),
        );
      });
    });
  });
}
