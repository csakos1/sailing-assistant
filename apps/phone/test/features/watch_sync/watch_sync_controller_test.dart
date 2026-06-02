import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/watch_sync/watch_sync_controller.dart';
import 'package:shared/shared.dart';

void main() {
  group('WatchSyncController.onTick', () {
    final baseTime = DateTime.utc(2026, 6, 2, 10, 30);

    WatchPayload payloadWithSog(double? sog, {DateTime? timestamp}) {
      return WatchPayload(timestamp: timestamp ?? baseTime, sogKnots: sog);
    }

    test('sends the first payload', () {
      // Arrange & Act
      final sent = <WatchPayload>[];
      WatchSyncController(
        buildPayload: () => payloadWithSog(6.4),
        transport: (payload) async => sent.add(payload),
      ).onTick();

      // Assert
      expect(sent, hasLength(1));
      expect(sent.single.sogKnots, equals(6.4));
    });

    test('does not resend an unchanged payload', () {
      // A build-idő változik a tickek között, de a props nem → nincs küldés.
      // Arrange & Act
      var clock = baseTime;
      final sent = <WatchPayload>[];
      final controller = WatchSyncController(
        buildPayload: () => payloadWithSog(6.4, timestamp: clock),
        transport: (payload) async => sent.add(payload),
      )..onTick();
      clock = baseTime.add(const Duration(milliseconds: 500));
      controller.onTick();

      // Assert
      expect(sent, hasLength(1));
    });

    test('resends when a displayed value changes', () {
      // Arrange & Act
      var sog = 6.4;
      final sent = <WatchPayload>[];
      final controller = WatchSyncController(
        buildPayload: () => payloadWithSog(sog),
        transport: (payload) async => sent.add(payload),
      )..onTick();
      sog = 7.1;
      controller.onTick();

      // Assert
      expect(sent, hasLength(2));
      expect(sent.last.sogKnots, equals(7.1));
    });
  });
}
