import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/crew_overview.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  final owner = testMember();
  final zoli = testMember(userId: 'u-zoli', name: 'Zoli', role: UserRole.crew);
  final adam = testMember(userId: 'u-adam', name: 'Ádám', role: UserRole.crew);
  final dori = testMember(userId: 'u-dori', name: 'Dóri', role: UserRole.crew);

  CrewOverview overviewOf({
    List<MemberInfo>? members,
    List<WebSession> sessions = const [],
  }) => CrewOverview(
    requests: const [],
    members: members ?? [owner, zoli, adam, dori],
    sessions: sessions,
  );

  group('members', () {
    test('the owner leads, the rest follow the Hungarian alphabet', () {
      // Arrange: a szerver bajtsorrendje az Adamot a Zoli moge tenne.
      final overview = overviewOf(members: [zoli, adam, owner, dori]);

      // Act
      final names = [
        for (final member in overview.orderedMembers) member.account.name,
      ];

      // Assert
      expect(names, ['Ákos', 'Ádám', 'Dóri', 'Zoli']);
    });

    test('the crew members leave out the owner', () {
      // Act
      final crew = overviewOf().crewMembers;

      // Assert
      expect(crew, [adam, dori, zoli]);
    });

    test('a removed member is not found', () {
      // Act
      final overview = overviewOf();

      // Assert
      expect(overview.memberById('u-dori'), dori);
      expect(overview.memberById('u-gone'), isNull);
    });
  });

  group('web activity', () {
    test('is the latest session of the member', () {
      // Arrange
      final early = testSession(
        id: 's-1',
        userId: 'u-dori',
        lastSeenAt: DateTime.utc(2026, 10, 7, 8),
      );
      final latest = testSession(
        id: 's-2',
        userId: 'u-dori',
        lastSeenAt: DateTime.utc(2026, 10, 7, 10),
      );
      final other = testSession(id: 's-3');

      // Act
      final overview = overviewOf(sessions: [latest, other, early]);

      // Assert
      expect(
        overview.lastWebActivityOf('u-dori'),
        DateTime.utc(2026, 10, 7, 10),
      );
      expect(overview.sessionCountOf('u-dori'), 2);
    });

    test('is unknown without a live session', () {
      // Act
      final overview = overviewOf();

      // Assert
      expect(overview.lastWebActivityOf('u-zoli'), isNull);
      expect(overview.sessionCountOf('u-zoli'), 0);
    });
  });
}
