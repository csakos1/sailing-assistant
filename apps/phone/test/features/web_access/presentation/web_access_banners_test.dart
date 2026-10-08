import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/presentation/web_access_banners.dart';
import 'package:phone/features/web_access/presentation/web_access_menu.dart';
import 'package:phone/features/web_access/presentation/web_access_refresher.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';
import 'web_access_test_app.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late int sessionsOpened;
  late int scannerOpened;
  late List<WebAccessMenuItem> selected;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    sessionsOpened = 0;
    scannerOpened = 0;
    selected = [];
    serveDeviceTokens(server);
    server.routes[mePath] = (_) => meResponse();
    server.routes[bannerPath] = (_) =>
        bannerResponse(suspicious: [testSuspiciousLogin()]);
  });

  Future<void> pumpHome(WidgetTester tester) => pumpWebAccessApp(
    tester,
    server: server,
    keys: keys,
    store: store,
    home: Scaffold(
      appBar: AppBar(
        actions: [WebAccessMenu(onSelected: selected.add)],
      ),
      body: WebAccessRefresher(
        child: Column(
          children: [
            WebAccessBanners(
              onOpenSessions: () => sessionsOpened++,
              onOpenScanner: () => scannerOpened++,
            ),
            const Expanded(child: Text('list')),
          ],
        ),
      ),
    ),
  );

  group('suspicious logins', () {
    testWidgets('an own fallback login shows its title and details', (
      tester,
    ) async {
      // Act
      await pumpHome(tester);

      // Assert
      expect(find.text('Belépés jelszóval'), findsOneWidget);
      expect(
        find.textContaining('Chrome · Windows · Wien, AT · '),
        findsOneWidget,
      );
      expect(find.text('Rendben'), findsOneWidget);
      expect(find.text('Kiléptetés'), findsOneWidget);
    });

    testWidgets("another user's login carries the name", (tester) async {
      // Arrange
      server.routes[bannerPath] = (_) => bannerResponse(
        suspicious: [
          testSuspiciousLogin(
            userId: 'user-2',
            userName: 'Dóri',
            method: LoginMethod.qr,
          ),
        ],
      );

      // Act
      await pumpHome(tester);

      // Assert
      expect(find.text('Dóri · Belépés más országból'), findsOneWidget);
    });

    testWidgets('an ended session offers no sign-out', (tester) async {
      // Arrange
      server.routes[bannerPath] = (_) =>
          bannerResponse(suspicious: [testSuspiciousLogin(sessionId: null)]);

      // Act
      await pumpHome(tester);

      // Assert
      expect(find.text('Rendben'), findsOneWidget);
      expect(find.text('Kiléptetés'), findsNothing);
    });

    testWidgets('acknowledging removes the banner', (tester) async {
      // Arrange
      final path = loginEventAcknowledgementPath('event-1');
      server.routes[path] = (_) => http.Response('', 204);
      await pumpHome(tester);
      server.routes[bannerPath] = (_) => bannerResponse();

      // Act
      await tester.tap(find.text('Rendben'));
      await tester.pumpAndSettle();

      // Assert
      expect(server.requestsTo(path), hasLength(1));
      expect(find.text('Belépés jelszóval'), findsNothing);
    });

    testWidgets('signing out ends the session', (tester) async {
      // Arrange
      final path = sessionPath('session-9');
      server.routes[path] = (_) => http.Response('', 204);
      await pumpHome(tester);
      server.routes[bannerPath] = (_) => bannerResponse();

      // Act
      await tester.tap(find.text('Kiléptetés'));
      await tester.pumpAndSettle();

      // Assert
      expect(server.requestsTo(path).single.method, 'DELETE');
      expect(find.text('Belépés jelszóval'), findsNothing);
    });

    testWidgets('a failed action shows a notice and keeps the banner', (
      tester,
    ) async {
      // Arrange
      server.routes[loginEventAcknowledgementPath('event-1')] = (_) =>
          http.Response('down', 502);
      await pumpHome(tester);

      // Act
      await tester.tap(find.text('Rendben'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
      expect(find.text('Belépés jelszóval'), findsOneWidget);
    });

    testWidgets('more than two logins fold into one row', (tester) async {
      // Arrange
      server.routes[bannerPath] = (_) => bannerResponse(
        suspicious: [
          for (final id in ['e1', 'e2', 'e3']) testSuspiciousLogin(id: id),
        ],
      );
      await pumpHome(tester);

      // Act
      await tester.tap(find.text('3 gyanús belépés'));
      await tester.pump();

      // Assert
      expect(find.text('Rendben'), findsNothing);
      expect(sessionsOpened, 1);
    });

    testWidgets('an unreachable server shows no banner', (tester) async {
      // Arrange
      server.routes[bannerPath] = (_) => http.Response('down', 502);

      // Act
      await pumpHome(tester);

      // Assert
      expect(find.text('Belépés jelszóval'), findsNothing);
      expect(find.text('Nincs kapcsolat a szerverrel'), findsNothing);
    });
  });

  group('revoked phone', () {
    setUp(() {
      server.routes[deviceChallengesPath] = (_) =>
          errorResponse(const DeviceRevoked());
    });

    testWidgets('the crew can ask to join again', (tester) async {
      // Arrange
      store.account = testAccount(role: UserRole.crew);
      await pumpHome(tester);

      // Act
      await tester.tap(find.text('Csatlakozás kérése'));
      await tester.pumpAndSettle();

      // Assert
      expect(keys.calls, contains('delete'));
      expect(store.account, isNull);
      expect(scannerOpened, 1);
    });

    testWidgets('the owner gets the CLI hint and no menu', (tester) async {
      // Act
      await pumpHome(tester);

      // Assert
      expect(find.text('Ez a telefon vissza lett vonva'), findsOneWidget);
      expect(
        find.text('Regisztráld újra a telefont a szerveren (CLI).'),
        findsOneWidget,
      );
      expect(find.text('Csatlakozás kérése'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('menu', () {
    testWidgets('lists the web sessions under the section label', (
      tester,
    ) async {
      // Arrange
      await pumpHome(tester);

      // Act
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('WEBES HOZZÁFÉRÉS'), findsOneWidget);
      await tester.tap(find.text('Webes belépések'));
      await tester.pumpAndSettle();

      // Assert
      expect(selected, [WebAccessMenuItem.sessions]);
    });

    testWidgets('is hidden without an account', (tester) async {
      // Arrange
      store.account = null;

      // Act
      await pumpHome(tester);

      // Assert
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(server.requests, isEmpty);
    });
  });
}
