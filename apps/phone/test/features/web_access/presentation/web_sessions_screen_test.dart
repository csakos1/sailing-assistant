import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/presentation/web_sessions_screen.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';
import 'web_access_test_app.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;

  final ownFallback = testSession(
    id: 'own-1',
    method: LoginMethod.password,
    isSuspicious: true,
  );
  final ownQr = testSession(id: 'own-2');
  final crewSession = testSession(
    id: 'crew-1',
    userId: 'user-2',
    userName: 'Dóri',
  );

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    server.routes[sessionsPath] = (_) =>
        sessionsResponse([crewSession, ownFallback, ownQr]);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) => meResponse();
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpWebAccessApp(
    tester,
    server: server,
    keys: keys,
    store: store,
    home: const WebSessionsScreen(),
  );

  testWidgets('the owner sees every user grouped, own group first', (
    tester,
  ) async {
    // Act
    await pumpScreen(tester);

    // Assert
    final own = tester.getTopLeft(find.text('ÁKOS · TE'));
    final crew = tester.getTopLeft(find.text('DÓRI'));
    expect(own.dy, lessThan(crew.dy));
    expect(find.text('Tartalék-belépés'), findsOneWidget);
    expect(find.text('JELSZÓ'), findsOneWidget);
    expect(find.text('QR'), findsNWidgets(2));
    expect(find.text('Kiléptetés'), findsNWidgets(3));
    expect(find.text('84.236.10.20 · Budapest, HU'), findsNWidgets(3));
    expect(find.text('IP-hely: DB-IP'), findsOneWidget);
  });

  testWidgets('the crew sees its own logins without group headers', (
    tester,
  ) async {
    // Arrange
    store.account = testAccount(role: UserRole.crew);
    server.routes[sessionsPath] = (_) => sessionsResponse([ownQr]);

    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('ÁKOS · TE'), findsNothing);
    expect(find.text('Firefox · Linux'), findsOneWidget);
  });

  testWidgets('signing out ends the session and reloads the list', (
    tester,
  ) async {
    // Arrange
    final path = sessionPath('crew-1');
    server.routes[path] = (_) => http.Response('', 204);
    await pumpScreen(tester);
    server.routes[sessionsPath] = (_) => sessionsResponse([ownFallback, ownQr]);

    // Act
    await tester.tap(find.text('Kiléptetés').last);
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(path).single.method, 'DELETE');
    expect(find.text('DÓRI'), findsNothing);
    expect(server.requestsTo(sessionsPath), hasLength(2));
  });

  testWidgets('an empty list says so', (tester) async {
    // Arrange
    server.routes[sessionsPath] = (_) => sessionsResponse(const []);

    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('Nincs aktív webes belépés'), findsOneWidget);
  });

  testWidgets('a load error offers a retry', (tester) async {
    // Arrange
    server.routes[sessionsPath] = (_) => http.Response('down', 502);
    await pumpScreen(tester);
    expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
    server.routes[sessionsPath] = (_) => sessionsResponse([ownQr]);

    // Act
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Firefox · Linux'), findsOneWidget);
  });

  testWidgets('a revoked phone shows no retry', (tester) async {
    // Arrange
    server.routes[deviceChallengesPath] = (_) =>
        errorResponse(const DeviceRevoked());

    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('Ez a telefon vissza lett vonva'), findsOneWidget);
    expect(find.text('Újra'), findsNothing);
  });
}
