import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/presentation/crew_screen.dart';
import 'package:phone/features/web_access/presentation/recovery_codes_screen.dart';
import 'package:phone/features/web_access/presentation/web_account_screen.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';
import 'web_access_test_app.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    serveActionChallenges(server);
    server.routes[accountSecurityPath] = (_) => securityResponse(
      recoveryCodesGeneratedAt: DateTime.utc(2026, 3, 2, 18),
    );
    server.routes[sessionsPath] = (_) => sessionsResponse([testSession()]);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) => meResponse();
    server.routes[joinRequestsPath] = (_) => joinRequestsResponse([]);
    server.routes[membersPath] = (_) => membersResponse([testMember()]);
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpWebAccessApp(
    tester,
    server: server,
    keys: keys,
    store: store,
    home: const WebAccountScreen(),
  );

  WebActionButton buttonLabelled(WidgetTester tester, String label) =>
      tester.widget<WebActionButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(WebActionButton),
        ),
      );

  group('owner', () {
    testWidgets('shows the name, the password, the codes and the phone', (
      tester,
    ) async {
      // Act
      await pumpScreen(tester);

      // Assert
      expect(find.text('Fiók és biztonság'), findsOneWidget);
      expect(find.text('NEVED'), findsOneWidget);
      expect(find.text('Ákos'), findsOneWidget);
      expect(find.text('Nincs jelszó'), findsOneWidget);
      expect(find.text('0 / 12'), findsOneWidget);
      expect(find.text('7 / 10'), findsOneWidget);
      expect(find.text('generálva márc. 2.'), findsOneWidget);
      expect(find.text('Google Pixel 9 Pro XL'), findsOneWidget);
      expect(find.text('Mentés'), findsNothing);
      expect(buttonLabelled(tester, 'Jelszó mentése').onPressed, isNull);
    });

    testWidgets('renaming saves the account and hides the button', (
      tester,
    ) async {
      // Arrange
      server.routes[accountNamePath] = (_) => meResponse(name: 'Ákos Cs.');
      await pumpScreen(tester);

      // Act
      await tester.enterText(find.text('Ákos'), 'Ákos Cs.');
      await tester.pump();
      await tester.tap(find.text('Mentés'));
      await tester.pumpAndSettle();

      // Assert
      expect(store.account?.account.name, 'Ákos Cs.');
      expect(find.text('Név mentve'), findsOneWidget);
      expect(find.text('Mentés'), findsNothing);
      expect(keys.prompts, isEmpty);
    });

    testWidgets('an invalid name is flagged and cannot be saved', (
      tester,
    ) async {
      // Arrange
      await pumpScreen(tester);

      // Act
      await tester.enterText(find.text('Ákos'), 'a' * 41);
      await tester.pump();

      // Assert
      expect(find.text('1–40 karakter, sortörés nélkül'), findsOneWidget);
      expect(find.text('Mentés'), findsNothing);
    });

    testWidgets('a password is saved after the fingerprint', (tester) async {
      // Arrange
      server.routes[accountPasswordPath] = (_) => http.Response('', 204);
      await pumpScreen(tester);
      final field = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.obscureText,
      );

      // Act
      await tester.enterText(field, 'rovid');
      await tester.pump();
      expect(find.text('5 / 12'), findsOneWidget);
      expect(buttonLabelled(tester, 'Jelszó mentése').onPressed, isNull);
      await tester.enterText(field, 'hajo-lola-balaton');
      await tester.pump();
      await tester.tap(find.text('Jelszó mentése'));
      await tester.pumpAndSettle();

      // Assert
      final body = FakeWebServer.bodyOf(
        server.requestsTo(accountPasswordPath).single,
      );
      expect(body['password'], 'hajo-lola-balaton');
      expect(keys.prompts.single.title, 'Webes jelszó beállítása');
      expect(keys.prompts.single.subtitle, 'localhost:8080');
      expect(find.text('Jelszó mentve'), findsOneWidget);
      expect(find.text('hajo-lola-balaton'), findsNothing);
    });

    testWidgets('new codes are confirmed, signed and shown once', (
      tester,
    ) async {
      // Arrange
      server.routes[accountRecoveryCodesPath] = (_) => jsonResponse(
        encodeIssuedRecoveryCodes(
          const IssuedRecoveryCodes(['ABCDE-FGHIJ', 'KLMNO-PQRST']),
        ),
        status: 201,
      );
      await pumpScreen(tester);

      // Act
      await tester.tap(find.text('Újragenerálás'));
      await tester.pumpAndSettle();
      expect(find.text('Új helyreállító kódok?'), findsOneWidget);
      await tester.tap(find.text('Újragenerálás').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(RecoveryCodesScreen), findsOneWidget);
      expect(find.text('ABCDE-FGHIJ'), findsOneWidget);
      expect(keys.prompts.single.title, 'Új helyreállító kódok');
      await tester.tap(find.text('Elmentettem'));
      await tester.pumpAndSettle();
      expect(find.byType(WebAccountScreen), findsOneWidget);
    });

    testWidgets('a failed security load keeps the name usable', (
      tester,
    ) async {
      // Arrange
      server.routes[accountSecurityPath] = (_) => http.Response('down', 502);

      // Act
      await pumpScreen(tester);

      // Assert
      expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
      expect(find.text('Újra'), findsOneWidget);
      expect(find.text('NEVED'), findsOneWidget);
    });

    testWidgets('the crew link opens the crew screen', (tester) async {
      // Arrange
      await pumpScreen(tester);

      // Act
      await tester.ensureVisible(find.text('Legénység'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Legénység'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CrewScreen), findsOneWidget);
    });
  });

  testWidgets('the crew sees only the name and the sessions link', (
    tester,
  ) async {
    // Arrange
    store.account = testAccount(role: UserRole.crew);
    server.routes[mePath] = (_) => meResponse(role: UserRole.crew);

    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('Fiók'), findsOneWidget);
    expect(find.text('WEBES JELSZÓ'), findsNothing);
    expect(find.text('Legénység'), findsNothing);
    expect(find.text('Webes belépések'), findsOneWidget);
    expect(server.requestsTo(accountSecurityPath), isEmpty);
  });
}
