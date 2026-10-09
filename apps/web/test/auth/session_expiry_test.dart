import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';
import 'package:race_archive_api/race_archive_api.dart';

import 'auth_fixtures.dart';
import 'fake_auth_server.dart';

// Egy munka kozbeni `401` a belepo kepernyore visz (ADR 0051 Addendum 7
// P1, P3), a valodi API-klienseken at.

void main() {
  testWidgets('a 401 from the archive shows the sign-in screen', (
    tester,
  ) async {
    // ARRANGE: a `me` meg el, de az archivum mar lejart munkamenetet lat
    const owner = AccountInfo(
      userId: 'user-1',
      name: 'Akos',
      role: UserRole.owner,
    );
    final server = FakeAuthServer()
      ..isArchiveUnauthorized = true
      ..me = () => jsonResponse(encodeAccountInfo(owner));

    // ACT
    await pumpAppOverHttp(tester, server);

    // ASSERT: a halk sorral
    expect(find.byType(QrCodeImage), findsOneWidget);
    expect(find.text('A belépés lejárt'), findsOneWidget);
    expect(find.text('Versenynapló'), findsNothing);

    // ACT: ujra belep
    server
      ..isArchiveUnauthorized = false
      ..pollState = LoginRequestState.signedIn;
    await advance(tester, const Duration(milliseconds: 1500));

    // ASSERT: a naplo ujratolt, nem a regi hiba latszik
    expect(find.text('Versenynapló'), findsOneWidget);
    expect(find.text('ÚJRA'), findsNothing);
  });
}
