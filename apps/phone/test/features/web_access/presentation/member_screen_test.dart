import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/presentation/member_screen.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';
import 'web_access_test_app.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;

  final galaxy = testMemberDevice(
    lastUsedAt: DateTime.utc(2026, 10, 7, 8, 5),
  );
  final dori = testMember(
    userId: 'u-dori',
    name: 'Dóri',
    role: UserRole.crew,
    devices: [galaxy],
  );
  final doriSession = testSession(
    id: 's-dori',
    userId: 'u-dori',
    userName: 'Dóri',
    lastSeenAt: DateTime.utc(2026, 10, 7, 10, 20),
  );

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    serveActionChallenges(server);
    server.routes[joinRequestsPath] = (_) => joinRequestsResponse([]);
    server.routes[membersPath] = (_) => membersResponse([testMember(), dori]);
    server.routes[sessionsPath] = (_) => sessionsResponse([doriSession]);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) => meResponse();
  });

  // A lap egy szulo-kepernyorol nyilik, hogy az eltavolitas utani
  // visszalepes latsszon.
  Future<void> pumpPage(
    WidgetTester tester, {
    String userId = 'u-dori',
    String name = 'Dóri',
  }) async {
    await pumpWebAccessApp(
      tester,
      server: server,
      keys: keys,
      store: store,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(
              MemberScreen.open(context, userId: userId, name: name),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the web activity and the devices', (tester) async {
    // Act
    await pumpPage(tester);

    // Assert
    expect(find.text('Utolsó webes aktivitás'), findsOneWidget);
    expect(find.text('40 perce'), findsOneWidget);
    expect(find.text('Webes munkamenet'), findsOneWidget);
    expect(find.text('ESZKÖZÖK'), findsOneWidget);
    expect(find.text('Galaxy S23'), findsOneWidget);
    expect(find.textContaining('regisztrálva '), findsOneWidget);
    expect(find.textContaining('utoljára '), findsOneWidget);
    expect(find.text('Visszavonás'), findsOneWidget);
    expect(find.text('Tag eltávolítása'), findsOneWidget);
  });

  testWidgets('revoking a phone signs it and reloads', (tester) async {
    // Arrange
    final path = deviceRevocationPath(galaxy.id);
    server.routes[path] = (_) {
      server.routes[membersPath] = (_) => membersResponse([
        testMember(),
        testMember(
          userId: 'u-dori',
          name: 'Dóri',
          role: UserRole.crew,
          devices: const [],
        ),
      ]);
      return http.Response('', 204);
    };
    await pumpPage(tester);

    // Act
    await tester.tap(find.text('Visszavonás'));
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(path), hasLength(1));
    expect(keys.prompts.single.title, 'Galaxy S23 visszavonása');
    expect(keys.prompts.single.subtitle, 'Dóri');
    expect(find.text('Nincs aktív telefonja'), findsOneWidget);
  });

  testWidgets('removing asks first, then leaves the page', (tester) async {
    // Arrange
    final path = memberRemovalPath('u-dori');
    server.routes[path] = (_) => http.Response('', 204);
    await pumpPage(tester);

    // Act
    await tester.tap(find.text('Tag eltávolítása'));
    await tester.pumpAndSettle();
    expect(find.text('Dóri eltávolítása?'), findsOneWidget);
    await tester.tap(find.text('Eltávolítás'));
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(path), hasLength(1));
    expect(keys.prompts.single.title, 'Dóri eltávolítása');
    expect(find.byType(MemberScreen), findsNothing);
  });

  testWidgets('cancelling the removal sends nothing', (tester) async {
    // Arrange
    await pumpPage(tester);

    // Act
    await tester.tap(find.text('Tag eltávolítása'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(memberRemovalPath('u-dori')), isEmpty);
    expect(keys.prompts, isEmpty);
    expect(find.byType(MemberScreen), findsOneWidget);
  });

  testWidgets("the owner's page keeps this phone and cannot be removed", (
    tester,
  ) async {
    // Act
    await pumpPage(tester, userId: 'user-1', name: 'Ákos');

    // Assert
    expect(find.text('Ez a telefon'), findsOneWidget);
    expect(find.text('Visszavonás'), findsNothing);
    expect(find.text('Tag eltávolítása'), findsNothing);
    expect(find.text('—'), findsOneWidget);
  });
}
