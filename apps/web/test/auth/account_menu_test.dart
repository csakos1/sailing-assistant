import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/account_menu.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';
import 'package:race_archive_api/race_archive_api.dart';

import 'auth_fixtures.dart';
import 'fake_auth_server.dart';

// A nev-menu es a kijelentkezes (17f, ADR 0051 Addendum 7 P7).

void main() {
  const owner = AccountInfo(
    userId: 'user-1',
    name: 'Akos',
    role: UserRole.owner,
  );

  FakeAuthServer ownerServer() =>
      FakeAuthServer()..me = () => jsonResponse(encodeAccountInfo(owner));

  testWidgets('shows the name, the role and signs out', (tester) async {
    // ARRANGE
    final server = ownerServer();
    await server.pumpApp(tester);

    // ACT
    await tester.tap(find.text('Akos'));
    await tester.pumpAndSettle();

    // ASSERT: a fejben a nev is ott van
    expect(find.text('Akos'), findsNWidgets(2));
    expect(find.text('TULAJDONOS'), findsOneWidget);

    // ACT
    await tester.tap(find.text('Kijelentkezés'));
    await flush(tester);

    // ASSERT: a belepo kepernyo, a lejart-sor nelkul
    expect(server.signOuts, 1);
    expect(find.byType(QrCodeImage), findsOneWidget);
    expect(find.text('A belépés lejárt'), findsNothing);
  });

  testWidgets('stays signed in and says so when the sign-out fails', (
    tester,
  ) async {
    // ARRANGE
    final server = ownerServer()
      ..logout = () => errorResponse(const InternalError());
    await server.pumpApp(tester);

    // ACT
    await tester.tap(find.text('Akos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kijelentkezés'));
    await flush(tester);

    // ASSERT
    expect(find.text('Versenynapló'), findsOneWidget);
    expect(find.byType(QrCodeImage), findsNothing);
    expect(
      find.text('Nem sikerült kijelentkezni. Próbáld újra.'),
      findsOneWidget,
    );
  });

  testWidgets('the owner row fits a 800 px window', (tester) async {
    // ARRANGE: a legkisebb tamogatott ablak (ADR 0049 Addendum 5 W3)
    final server = ownerServer();
    await server.pumpApp(tester);
    tester.view.physicalSize = const Size(800, 900);

    // ACT
    await tester.pumpAndSettle();

    // ASSERT: minden vezerlo latszik; a nev-menu ikon, a nev a tooltipben
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Akos'), findsOneWidget);
    expect(find.text('Akos'), findsNothing);
    expect(find.text('Új verseny'), findsOneWidget);
    expect(find.text('Feltöltés'), findsOneWidget);
    expect(find.byTooltip('Statisztika'), findsOneWidget);
    expect(find.byTooltip('Export'), findsOneWidget);
    expect(tester.getRect(find.byType(AccountMenu)).right, lessThan(800));
  });

  testWidgets('the narrow icon opens the same menu', (tester) async {
    // ARRANGE
    final server = ownerServer();
    await server.pumpApp(tester);
    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();

    // ACT
    await tester.tap(find.byTooltip('Akos'));
    await tester.pumpAndSettle();

    // ASSERT
    expect(find.text('Akos'), findsOneWidget);
    expect(find.text('TULAJDONOS'), findsOneWidget);
    expect(find.text('Kijelentkezés'), findsOneWidget);
  });
}
