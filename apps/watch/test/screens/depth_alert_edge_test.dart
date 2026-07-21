import 'package:flutter_test/flutter_test.dart';
import 'package:watch/screens/depth_alert_edge.dart';

void main() {
  group('isRisingDepthBuzz', () {
    test('a számláló nő aktív riasztás alatt → rezeg', () {
      expect(
        isRisingDepthBuzz(
          previousCounter: 2,
          currentCounter: 3,
          currentDepthMeters: 2.3,
        ),
        isTrue,
      );
    });

    test('a számláló nem változik → nem rezeg', () {
      expect(
        isRisingDepthBuzz(
          previousCounter: 3,
          currentCounter: 3,
          currentDepthMeters: 2.3,
        ),
        isFalse,
      );
    });

    test('a számláló visszaesik (engine-újraindulás) → MÉGIS rezeg', () {
      // Az engine in-memory számlálója újraindulásnál nullázódik. Egy `>`
      // összehasonlítás itt csendben elnyelné a riasztást; a zátonyveszélynél
      // a téves rezgés olcsóbb hiba, mint az elmaradt.
      expect(
        isRisingDepthBuzz(
          previousCounter: 7,
          currentCounter: 1,
          currentDepthMeters: 2.2,
        ),
        isTrue,
      );
    });

    test('nincs aktív riasztás → a számláló-változás sem rezeg', () {
      expect(
        isRisingDepthBuzz(
          previousCounter: 7,
          currentCounter: 1,
          currentDepthMeters: null,
        ),
        isFalse,
      );
    });

    test('induló payload aktív riasztással → rezeg', () {
      expect(
        isRisingDepthBuzz(
          previousCounter: 0,
          currentCounter: 1,
          currentDepthMeters: 2.4,
        ),
        isTrue,
      );
    });
  });

  group('isDepthAlertVisible', () {
    test('aktív riasztás, még semmit nem zártak be → látszik', () {
      expect(
        isDepthAlertVisible(
          depthAlertMeters: 2.4,
          depthBuzzCounter: 1,
          dismissedAtCounter: null,
        ),
        isTrue,
      );
    });

    test('nincs aktív riasztás → nem látszik', () {
      expect(
        isDepthAlertVisible(
          depthAlertMeters: null,
          depthBuzzCounter: 3,
          dismissedAtCounter: null,
        ),
        isFalse,
      );
    });

    test('pont ezt a számláló-értéket zárták be → nem látszik', () {
      expect(
        isDepthAlertVisible(
          depthAlertMeters: 2.4,
          depthBuzzCounter: 3,
          dismissedAtCounter: 3,
        ),
        isFalse,
      );
    });

    test('bezárás után tovább sekélyedik → újra látszik', () {
      // A ratchet UI-oldali párja: a bezárás addig tart, amíg nem romlik.
      expect(
        isDepthAlertVisible(
          depthAlertMeters: 2.2,
          depthBuzzCounter: 4,
          dismissedAtCounter: 3,
        ),
        isTrue,
      );
    });

    test('bezárás után új epizód alacsonyabb számlálóval → látszik', () {
      expect(
        isDepthAlertVisible(
          depthAlertMeters: 2.4,
          depthBuzzCounter: 1,
          dismissedAtCounter: 5,
        ),
        isTrue,
      );
    });
  });
}
