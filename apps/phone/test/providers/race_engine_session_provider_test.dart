import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/race_engine_session_provider.dart';

void main() {
  group('raceEngineSessionProvider', () {
    test('kezdő állapot false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(raceEngineSessionProvider), isFalse);
    });

    test('start() true-ra, stop() false-ra billent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(raceEngineSessionProvider.notifier).start();
      expect(container.read(raceEngineSessionProvider), isTrue);

      container.read(raceEngineSessionProvider.notifier).stop();
      expect(container.read(raceEngineSessionProvider), isFalse);
    });
  });
}
