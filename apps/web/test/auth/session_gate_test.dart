import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';
import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';

import 'auth_fixtures.dart';
import 'fake_auth_server.dart';

// A munkamenet-kapu indulaskor (ADR 0051 Addendum 7 P2).

void main() {
  const owner = AccountInfo(
    userId: 'user-1',
    name: 'Akos',
    role: UserRole.owner,
  );

  testWidgets('a live session opens the log without the sign-in screen', (
    tester,
  ) async {
    // ARRANGE
    final server = FakeAuthServer()
      ..me = () => jsonResponse(encodeAccountInfo(owner));

    // ACT
    await server.pumpApp(tester);

    // ASSERT
    expect(find.text('Versenynapló'), findsOneWidget);
    expect(find.byType(QrCodeImage), findsNothing);
    expect(server.openedRequests, 0);
  });

  testWidgets('no session shows the sign-in screen and loads nothing', (
    tester,
  ) async {
    // ARRANGE
    final server = FakeAuthServer();

    // ACT
    await server.pumpApp(tester);

    // ASSERT: a lejart-sor csak munka kozbeni lejaratnal latszik
    expect(find.byType(QrCodeImage), findsOneWidget);
    expect(find.text('A belépés lejárt'), findsNothing);
    expect(find.text('Versenynapló'), findsNothing);
    expect(server.archiveRequests, 0);
  });

  testWidgets('an unreachable server offers a retry', (tester) async {
    // ARRANGE
    final server = FakeAuthServer()
      ..me = () => throw http.ClientException('offline');
    await server.pumpApp(tester);
    expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
    expect(find.byType(QrCodeImage), findsNothing);

    // ACT
    server.me = () => jsonResponse(encodeAccountInfo(owner));
    await tester.tap(find.text('ÚJRA'));
    await flush(tester);

    // ASSERT
    expect(find.text('Versenynapló'), findsOneWidget);
  });
}
