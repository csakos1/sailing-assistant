import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/presentation/join_formatters.dart';

void main() {
  group('joinTimeLeft', () {
    test('splits the remaining time into whole hours and minutes', () {
      // Arrange
      final now = DateTime.utc(2026, 10, 7, 11);
      final expiresAt = now.add(const Duration(hours: 23, minutes: 59));

      // Act
      final left = joinTimeLeft(expiresAt, now);

      // Assert
      expect(left, (hours: 23, minutes: 59));
    });

    test('drops the seconds instead of rounding up', () {
      // Arrange
      final now = DateTime.utc(2026, 10, 7, 11);
      final expiresAt = now.add(const Duration(minutes: 1, seconds: 59));

      // Act
      final left = joinTimeLeft(expiresAt, now);

      // Assert
      expect(left, (hours: 0, minutes: 1));
    });

    test('an expired request has nothing left', () {
      // Arrange
      final now = DateTime.utc(2026, 10, 7, 11);

      // Act
      final left = joinTimeLeft(now.subtract(const Duration(hours: 1)), now);

      // Assert
      expect(left, (hours: 0, minutes: 0));
    });
  });

  group('formatLocalClock', () {
    test('pads the local hour and minute to two digits', () {
      // Arrange
      final moment = DateTime(2026, 10, 7, 9, 5);

      // Act
      final text = formatLocalClock(moment);

      // Assert
      expect(text, '09:05');
    });
  });
}
