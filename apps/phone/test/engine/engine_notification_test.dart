import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/engine/engine_notification.dart';

void main() {
  group('engineNotificationTitle (ADR 0054 D5)', () {
    test('shows the race title only while a race is active', () {
      expect(
        engineNotificationTitle(RaceStatus.active),
        engineNotificationTitleRace,
      );
    });

    test('shows the instruments title in every other mode', () {
      // Free mode, pre-start and after the finish.
      for (final status in [null, RaceStatus.notStarted, RaceStatus.finished]) {
        expect(
          engineNotificationTitle(status),
          engineNotificationTitleInstruments,
          reason: '$status',
        );
      }
    });
  });
}
