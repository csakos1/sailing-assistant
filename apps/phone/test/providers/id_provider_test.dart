import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/id_provider.dart';

void main() {
  group('idProvider', () {
    test('alapból nem-üres, egymástól különböző id-kat ad', () {
      // ARRANGE
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // ACT
      final generate = container.read(idProvider);
      final first = generate();
      final second = generate();

      // ASSERT
      expect(first, isNotEmpty);
      expect(first, isNot(second));
    });

    test('override determinisztikus id-t ad', () {
      // ARRANGE
      final container = ProviderContainer(
        overrides: [idProvider.overrideWithValue(() => 'fixed-id')],
      );
      addTearDown(container.dispose);

      // ACT & ASSERT
      expect(container.read(idProvider)(), 'fixed-id');
    });
  });
}
