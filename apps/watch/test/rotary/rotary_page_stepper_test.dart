import 'package:flutter_test/flutter_test.dart';
import 'package:watch/rotary/rotary_page_stepper.dart';

void main() {
  group('RotaryPageStepper', () {
    test('does not step below the threshold', () {
      // Arrange / Act / Assert — fél detent nem lép.
      final stepper = RotaryPageStepper();
      expect(stepper.addDelta(0.6), 0);
    });

    test('steps once when the accumulated delta reaches the threshold', () {
      // Arrange — 0.6 felgyűlt; a cascade a konstruktorra fűzve.
      final stepper = RotaryPageStepper()..addDelta(0.6);

      // Act / Assert — 0.6 + 0.6 = 1.2 ≥ 1.0 → egy lépés előre.
      expect(stepper.addDelta(0.6), 1);
    });

    test('carries the residual into the next step', () {
      // Arrange — 1.2 → lépés, 0.2 marad.
      final stepper = RotaryPageStepper()
        ..addDelta(0.6)
        ..addDelta(0.6);

      // Act / Assert — 0.2 + 0.9 = 1.1 ≥ 1.0 → újabb lépés.
      expect(stepper.addDelta(0.9), 1);
    });

    test('steps backward on negative deltas', () {
      // Arrange / Act / Assert
      final stepper = RotaryPageStepper();
      expect(stepper.addDelta(-1), -1);
    });

    test('opposite motion cancels partial accumulation', () {
      // Arrange — 0.6 felgyűlt.
      final stepper = RotaryPageStepper()..addDelta(0.6);

      // Act / Assert — 0.6 - 0.6 = 0 → nincs lépés; majd -1.0 → -1.
      expect(stepper.addDelta(-0.6), 0);
      expect(stepper.addDelta(-1), -1);
    });

    test('emits multiple steps for a large delta', () {
      // Arrange / Act / Assert — 2.5 / 1.0 → 2 lépés, 0.5 marad.
      final stepper = RotaryPageStepper();
      expect(stepper.addDelta(2.5), 2);
    });

    test('honours a custom threshold', () {
      // Arrange — 2.0-s küszöb.
      final stepper = RotaryPageStepper(threshold: 2);

      // Act / Assert — 1.5 nem lép; +0.5 = 2.0 → egy lépés.
      expect(stepper.addDelta(1.5), 0);
      expect(stepper.addDelta(0.5), 1);
    });
  });
}
