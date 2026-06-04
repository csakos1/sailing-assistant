import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:watch/watch_sync/watch_state_provider.dart';

void main() {
  final buildTime = DateTime.utc(2026, 6, 2, 10, 30);

  group('decodeWatchPayload', () {
    test('decodes a native JSON string into a WatchPayload', () {
      // Arrange — a phone által küldött alak (epoch millis + knots).
      final json = jsonEncode(
        WatchPayload(timestamp: buildTime, sogKnots: 6.4).toJson(),
      );

      // Act
      final payload = decodeWatchPayload(json);

      // Assert
      expect(payload.timestamp, equals(buildTime));
      expect(payload.sogKnots, equals(6.4));
    });
  });

  group('watchStateProvider', () {
    test('emits decoded payloads from the injected source', () async {
      // Arrange — platform nélküli fake forrás a DIP-seamen át injektálva.
      final controller = StreamController<String>();
      addTearDown(controller.close);
      final container = ProviderContainer(
        overrides: [
          watchStateSourceProvider.overrideWithValue(() => controller.stream),
        ],
      );
      addTearDown(container.dispose);
      // A provider olvasása feliratkoztatja a forrásra.
      final firstPayload = container.read(watchStateProvider.future);

      // Act
      controller.add(
        jsonEncode(WatchPayload(timestamp: buildTime, sogKnots: 6.4).toJson()),
      );

      // Assert
      final payload = await firstPayload;
      expect(payload.sogKnots, equals(6.4));
    });
  });
}
