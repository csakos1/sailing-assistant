import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/watch_sync/watch_clock_provider.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

void main() {
  group('watchClockProvider', () {
    test('emits an untrusted reading before any payload', () async {
      // Arrange — soha nem emittáló forrás (üres stream tearoff).
      final container = ProviderContainer(
        overrides: [
          watchStateSourceProvider.overrideWithValue(Stream<String>.empty),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(watchClockProvider, (_, _) {});
      addTearDown(sub.close);

      // Act — a kezdeti emit propagálódjon a streamen.
      await Future<void>.delayed(Duration.zero);
      final reading = container.read(watchClockProvider).value;

      // Assert
      expect(reading?.isTrusted, isFalse);
      expect(reading?.displayUtc, isNull);
    });

    test('emits a trusted reading after a trusted payload arrives', () async {
      // Arrange — egy megbízható payload a forráson át.
      final anchor = DateTime.utc(2026, 6, 2, 10, 30);
      final json = jsonEncode(
        WatchPayload(
          timestamp: anchor,
          gpsTimeUtc: anchor,
          isGpsTimeTrusted: true,
        ).toJson(),
      );
      final container = ProviderContainer(
        overrides: [
          watchStateSourceProvider.overrideWithValue(
            () => Stream<String>.value(json),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(watchClockProvider, (_, _) {});
      addTearDown(sub.close);

      // Act — a payload kézbesítve, majd a listen→emit lefut.
      await container.read(watchStateProvider.future);
      await Future<void>.delayed(Duration.zero);
      final reading = container.read(watchClockProvider).value;

      // Assert — valós Stopwatch, ezért tartomány: anchor ≤ kijelzett < +2 mp.
      expect(reading?.isTrusted, isTrue);
      expect(reading!.displayUtc, isNotNull);
      final shown = reading.displayUtc!;
      expect(shown.isBefore(anchor), isFalse);
      expect(shown.isBefore(anchor.add(const Duration(seconds: 2))), isTrue);
    });
  });
}
