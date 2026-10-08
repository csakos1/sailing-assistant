import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/presentation/crew_screen.dart';
import 'package:phone/features/web_access/presentation/member_screen.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';
import 'web_access_test_app.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;

  final request = testPendingRequest();
  final dori = testMember(
    userId: 'u-dori',
    name: 'Dóri',
    role: UserRole.crew,
    devices: [testMemberDevice()],
  );
  final approvalPath = joinRequestApprovalPath(request.id);

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    serveActionChallenges(server);
    server.routes[joinRequestsPath] = (_) => joinRequestsResponse([request]);
    server.routes[membersPath] = (_) => membersResponse([dori, testMember()]);
    server.routes[sessionsPath] = (_) => sessionsResponse([testSession()]);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) => meResponse();
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpWebAccessApp(
    tester,
    server: server,
    keys: keys,
    store: store,
    home: const CrewScreen(),
  );

  // A kerelem a dontes utan eltunik a listarol.
  void decideRequest(http.Response Function() answer) {
    server.routes[approvalPath] = (_) {
      server.routes[joinRequestsPath] = (_) => joinRequestsResponse([]);
      return answer();
    };
  }

  testWidgets('shows the request card and the members, owner first', (
    tester,
  ) async {
    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('FÜGGŐ KÉRELEM'), findsOneWidget);
    expect(find.text('Gergő'), findsOneWidget);
    expect(find.text('lejár 23 ó múlva'), findsOneWidget);
    expect(find.text('Pixel 7a'), findsOneWidget);
    expect(find.text('91.120.5.6 · Keszthely, HU'), findsOneWidget);
    expect(find.text('12 perce'), findsOneWidget);
    expect(find.text('TULAJDONOS'), findsOneWidget);
    expect(find.text('1 eszköz · web: 2 perce'), findsOneWidget);
    expect(find.text('1 eszköz · web: —'), findsOneWidget);
    final owner = tester.getTopLeft(find.text('Ákos'));
    final crew = tester.getTopLeft(find.text('Dóri'));
    expect(owner.dy, lessThan(crew.dy));
  });

  testWidgets('without requests only the members are listed', (tester) async {
    // Arrange
    server.routes[joinRequestsPath] = (_) => joinRequestsResponse([]);

    // Act
    await pumpScreen(tester);

    // Assert
    expect(find.text('FÜGGŐ KÉRELEM'), findsNothing);
    expect(find.text('TAGOK'), findsOneWidget);
  });

  testWidgets('rejecting sends no fingerprint and drops the card', (
    tester,
  ) async {
    // Arrange
    final path = joinRequestRejectionPath(request.id);
    server.routes[path] = (_) {
      server.routes[joinRequestsPath] = (_) => joinRequestsResponse([]);
      return http.Response('', 204);
    };
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Elutasítás'));
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(path), hasLength(1));
    expect(keys.prompts, isEmpty);
    expect(find.text('Gergő'), findsNothing);
  });

  testWidgets('approving as a new member asks for the fingerprint', (
    tester,
  ) async {
    // Arrange
    decideRequest(() => jsonResponse(encodeMemberInfo(dori)));
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Jóváhagyás'));
    await tester.pumpAndSettle();
    expect(find.text('Gergő jóváhagyása'), findsOneWidget);
    expect(find.text('Új tag'), findsOneWidget);
    expect(find.text('Dóri új telefonja'), findsOneWidget);
    expect(find.text('Ákos új telefonja'), findsNothing);
    await tester.tap(find.text('Jóváhagyás').last);
    await tester.pumpAndSettle();

    // Assert
    final body = FakeWebServer.bodyOf(server.requestsTo(approvalPath).single);
    expect(body['memberId'], isNull);
    expect(keys.prompts.single.title, 'Gergő jóváhagyása');
    expect(keys.prompts.single.subtitle, 'Pixel 7a · Keszthely, HU');
    expect(find.text('FÜGGŐ KÉRELEM'), findsNothing);
  });

  testWidgets("approving as an existing member's phone", (tester) async {
    // Arrange
    decideRequest(() => jsonResponse(encodeMemberInfo(dori)));
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Jóváhagyás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dóri új telefonja'));
    await tester.pump();
    await tester.tap(find.text('Jóváhagyás').last);
    await tester.pumpAndSettle();

    // Assert
    final body = FakeWebServer.bodyOf(server.requestsTo(approvalPath).single);
    expect(body['memberId'], 'u-dori');
  });

  testWidgets('closing the sheet approves nothing', (tester) async {
    // Arrange
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Jóváhagyás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();

    // Assert
    expect(server.requestsTo(approvalPath), isEmpty);
    expect(keys.prompts, isEmpty);
    expect(find.text('Gergő'), findsOneWidget);
  });

  testWidgets('a request decided elsewhere shows a notice', (tester) async {
    // Arrange
    decideRequest(() => errorResponse(const RequestExpired()));
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Jóváhagyás'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jóváhagyás').last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Ez már nem érvényes'), findsOneWidget);
    expect(find.text('FÜGGŐ KÉRELEM'), findsNothing);
  });

  testWidgets('a member row opens the member page', (tester) async {
    // Arrange
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text('Dóri'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(MemberScreen), findsOneWidget);
    expect(find.text('Galaxy S23'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    // Arrange
    server.routes[membersPath] = (_) => http.Response('down', 502);
    await pumpScreen(tester);
    server.routes[membersPath] = (_) => membersResponse([testMember()]);

    // Act
    expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('TAGOK'), findsOneWidget);
  });
}
