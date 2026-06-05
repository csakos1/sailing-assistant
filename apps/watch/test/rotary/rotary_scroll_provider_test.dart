import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch/rotary/rotary_scroll_provider.dart';

void main() {
  group('rotaryPageSteps', () {
    test('maps accumulated deltas into signed, non-zero page steps', () async {
      // Arrange / Act — fél-detentek és teljes forgatások vegyesen.
      final steps = await rotaryPageSteps(
        Stream<double>.fromIterable([0.6, 0.6, -1, -1]),
      ).toList();

      // Assert — 0.6→0(kihagy); 0.6→+1 (0.2 marad); -1→0(kihagy, -0.8 marad);
      // -1→-1 (a -0.8-ból átvitt maradékkal).
      expect(steps, [1, -1]);
    });
  });

  group('rotaryPageStepProvider', () {
    test('emits steps decoded from the injected source', () async {
      // Arrange — fake delta-forrás a seamen át (platform nélkül).
      final container = ProviderContainer(
        overrides: [
          rotaryScrollSourceProvider.overrideWithValue(
            () => Stream<double>.fromIterable([1, 1]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act — az első kibocsátott lap-lépés.
      final first = await container.read(rotaryPageStepProvider.future);

      // Assert — 1.0 → +1.
      expect(first, 1);
    });
  });
}
