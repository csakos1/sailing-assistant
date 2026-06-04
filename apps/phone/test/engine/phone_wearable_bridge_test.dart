import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/phone_wearable_bridge.dart';
import 'package:shared/shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneWearableBridge.send', () {
    const channel = MethodChannel('test/foretack/wearable');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    final payload = WatchPayload(
      timestamp: DateTime.utc(2026, 6, 2, 10, 30),
      sogKnots: 6.4,
    );

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('invokes putRaceState with the payload JSON', () async {
      // Arrange
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final bridge = PhoneWearableBridge(channel: channel);

      // Act
      await bridge.send(payload);

      // Assert
      expect(calls, hasLength(1));
      expect(calls.single.method, equals('putRaceState'));
      final decoded =
          jsonDecode(calls.single.arguments as String) as Map<String, dynamic>;
      expect(decoded['sogKnots'], equals(6.4));
    });

    test('swallows a platform error instead of throwing', () async {
      // A WatchTransport szerződés szerint a hibát a bridge nyeli el.
      // Arrange
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'WEARABLE_ERROR');
      });
      final bridge = PhoneWearableBridge(channel: channel);

      // Act & Assert
      await expectLater(bridge.send(payload), completes);
    });

    test('swallows a missing native handler', () async {
      // Nincs regisztrált handler ezen a csatornán → MissingPluginException.
      // Arrange
      final bridge = PhoneWearableBridge(
        channel: const MethodChannel('test/foretack/no-handler'),
      );

      // Act & Assert
      await expectLater(bridge.send(payload), completes);
    });
  });
}
