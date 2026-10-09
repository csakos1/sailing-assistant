import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/web_session_groups.dart';

import '../web_access_fakes.dart';

void main() {
  group('groupWebSessions', () {
    test('the own group leads, the rest follow the Hungarian order', () {
      // Arrange
      final sessions = [
        testSession(id: 'z', userId: 'u-zoli', userName: 'Zoli'),
        testSession(id: 'a', userId: 'u-adam', userName: 'Ádám'),
        testSession(id: 'own'),
        testSession(id: 'b', userId: 'u-bence', userName: 'Bence'),
      ];

      // Act
      final groups = groupWebSessions(sessions, ownUserId: 'user-1');

      // Assert
      expect(
        [for (final group in groups) group.userName],
        [
          'Ákos',
          'Ádám',
          'Bence',
          'Zoli',
        ],
      );
    });

    test('within a group the most recently active comes first', () {
      // Arrange
      final older = testSession(
        id: 'older',
        lastSeenAt: DateTime.utc(2026, 10, 6, 9),
      );
      final newer = testSession(
        id: 'newer',
        lastSeenAt: DateTime.utc(2026, 10, 7, 9),
      );

      // Act
      final groups = groupWebSessions([older, newer], ownUserId: 'user-1');

      // Assert
      expect(groups.single.sessions, [newer, older]);
    });

    test('no sessions make no groups', () {
      expect(groupWebSessions(const [], ownUserId: 'user-1'), isEmpty);
    });
  });
}
