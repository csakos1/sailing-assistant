import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/auth/sign_in/qr_code_image.dart';
import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';

import 'auth_fixtures.dart';
import 'fake_auth_server.dart';

// A belepo kepernyo a teljes appon at (ADR 0051 Addendum 7 P4, P5, P8):
// a QR-belepes szakaszai a teszt orajaval, es a tartalek urlap.

void main() {
  const pollStep = Duration(milliseconds: 1500);

  group('QR sign-in', () {
    testWidgets('shows the QR and counts down from the response', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();

      // ACT
      await server.pumpApp(tester);

      // ASSERT
      expect(find.text('Lola versenyarchívum'), findsOneWidget);
      expect(find.byType(QrCodeImage), findsOneWidget);
      expect(find.text('Olvasd be a Foretack appal'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
      expect(server.archiveRequests, 0);

      // ACT: egy masodperc
      await advance(tester, const Duration(seconds: 1));

      // ASSERT
      expect(find.text('0:59'), findsOneWidget);
    });

    testWidgets('waits for the phone, then opens the log', (tester) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);

      // ACT: a telefon megnyitja a kerest
      server.pollState = LoginRequestState.opened;
      await advance(tester, pollStep);

      // ASSERT: 17c, nev es eszkoz nelkul, visszaszamlalo nelkul
      expect(find.text('Erősítsd meg a telefonodon'), findsOneWidget);
      expect(find.byType(QrCodeImage), findsNothing);
      expect(find.text('Akos'), findsNothing);
      expect(find.text('Vissza a QR-kódhoz'), findsOneWidget);

      // ACT: jovahagyas
      server.pollState = LoginRequestState.signedIn;
      await advance(tester, pollStep);

      // ASSERT
      expect(find.text('Versenynapló'), findsOneWidget);
      expect(server.archiveRequests, 1);
    });

    testWidgets('counts ten minutes for a join request, then expires', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);

      // ACT: csatlakozasi kerelem
      server.pollState = LoginRequestState.joinPending;
      await advance(tester, pollStep);

      // ASSERT: 17d-1
      expect(find.text('KÉRELEM ELKÜLDVE'), findsOneWidget);
      expect(find.text('A tulajdonos jóváhagyására vár'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);

      // ACT: a tulajdonos nem hagyja jova, a keres lejar
      server.pollState = LoginRequestState.expired;
      await advance(tester, pollStep);
      server.pollState = LoginRequestState.pending;
      await advance(tester, const Duration(milliseconds: 300));

      // ASSERT: 17d-2, uj QR a jelzessel
      expect(server.openedRequests, 2);
      expect(find.byType(QrCodeImage), findsOneWidget);
      expect(find.text('Lejárt — olvasd be újra'), findsOneWidget);
      expect(find.text('Olvasd be a Foretack appal'), findsNothing);
    });

    testWidgets('refreshes an unscanned QR after sixty seconds', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);

      // ACT
      await advance(tester, const Duration(seconds: 59));

      // ASSERT: meg az elso kod
      expect(server.openedRequests, 1);
      expect(find.text('0:01'), findsOneWidget);

      // ACT
      await advance(tester, const Duration(seconds: 1));
      await advance(tester, const Duration(milliseconds: 300));

      // ASSERT: csendes frissites, jelzes nelkul
      expect(server.openedRequests, 2);
      expect(find.text('1:00'), findsOneWidget);
      expect(find.text('Olvasd be a Foretack appal'), findsOneWidget);
    });

    testWidgets('a silently expired QR is replaced without a notice', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);

      // ACT: a szerver szerint lejart, mielott a web visszaszamlalt volna
      server.pollState = LoginRequestState.expired;
      await advance(tester, pollStep);
      server.pollState = LoginRequestState.pending;
      await advance(tester, const Duration(milliseconds: 300));

      // ASSERT
      expect(server.openedRequests, 2);
      expect(find.text('Lejárt — olvasd be újra'), findsNothing);
    });

    testWidgets('goes back to a new QR from the waiting box', (tester) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);
      server.pollState = LoginRequestState.opened;
      await advance(tester, pollStep);
      server.pollState = LoginRequestState.pending;

      // ACT
      await tester.tap(find.text('Vissza a QR-kódhoz'));
      await advance(tester, const Duration(milliseconds: 300));

      // ASSERT
      expect(server.openedRequests, 2);
      expect(find.byType(QrCodeImage), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
    });

    testWidgets('reports the connection only after three failed polls', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();
      await server.pumpApp(tester);
      server.isPollFailing = true;

      // ACT
      await advance(tester, pollStep);
      await advance(tester, pollStep);

      // ASSERT
      expect(find.text('Nincs kapcsolat a szerverrel'), findsNothing);

      // ACT
      await advance(tester, pollStep);

      // ASSERT: a felirat helyen
      expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
      expect(find.text('Olvasd be a Foretack appal'), findsNothing);

      // ACT: egy sikeres lekerdezes visszaallitja
      server.isPollFailing = false;
      await advance(tester, pollStep);

      // ASSERT
      expect(find.text('Nincs kapcsolat a szerverrel'), findsNothing);
    });
  });

  group('fallback sign-in', () {
    Future<void> openFallback(
      WidgetTester tester,
      FakeAuthServer server,
    ) async {
      await server.pumpApp(tester);
      await tester.tap(find.text('Belépés jelszóval vagy helyreállító kóddal'));
      await flush(tester);
    }

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller?.text ?? '';

    testWidgets('signs in with Enter and opens the log', (tester) async {
      // ARRANGE
      final server = FakeAuthServer()
        ..fallback = () => jsonResponse(
          encodeAccountInfo(
            const AccountInfo(
              userId: 'user-1',
              name: 'Akos',
              role: UserRole.owner,
            ),
          ),
        );
      await openFallback(tester, server);

      // ACT
      await tester.enterText(find.byType(TextField), 'K7Q2M-AXWPD');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await flush(tester);

      // ASSERT
      expect(server.fallbackBodies, ['{"secret":"K7Q2M-AXWPD"}']);
      expect(find.text('Versenynapló'), findsOneWidget);
    });

    testWidgets('a rejected secret clears the field with a neutral line', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer();
      await openFallback(tester, server);

      // ACT
      await tester.enterText(find.byType(TextField), 'rossz-jelszo-123');
      await tester.tap(find.text('Belépés'));
      await flush(tester);

      // ASSERT: 17e-2
      expect(find.text('Nem sikerült belépni'), findsOneWidget);
      expect(fieldText(tester), isEmpty);

      // ACT: az uj gepeles eltunteti a sort
      await tester.enterText(find.byType(TextField), 'm');
      await tester.pump();

      // ASSERT
      expect(find.text('Nem sikerült belépni'), findsNothing);
    });

    testWidgets('waits out the limit minute by minute', (tester) async {
      // ARRANGE: 200 mp varakozas -> 4 perc felfele kerekitve
      final server = FakeAuthServer()
        ..fallback = () => errorResponse(const TooManyAttempts(200));
      await openFallback(tester, server);

      // ACT
      await tester.enterText(find.byType(TextField), 'rossz-jelszo-123');
      await tester.tap(find.text('Belépés'));
      await flush(tester);

      // ASSERT: 17e-3
      expect(find.text('Próbáld újra 4 perc múlva'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      // ACT: 81 mp mulva 119 mp van hatra
      await advance(tester, const Duration(seconds: 81));

      // ASSERT
      expect(find.text('Próbáld újra 2 perc múlva'), findsOneWidget);

      // ACT
      await advance(tester, const Duration(seconds: 119));

      // ASSERT: ujra probalhato
      expect(find.textContaining('Próbáld újra'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('keeps the text when the server is unreachable', (
      tester,
    ) async {
      // ARRANGE
      final server = FakeAuthServer()
        ..fallback = () => throw http.ClientException('offline');
      await openFallback(tester, server);

      // ACT
      await tester.enterText(find.byType(TextField), 'nagyon-titkos-jelszo');
      await tester.tap(find.text('Belépés'));
      await flush(tester);

      // ASSERT
      expect(find.text('Nincs kapcsolat a szerverrel'), findsOneWidget);
      expect(fieldText(tester), 'nagyon-titkos-jelszo');
    });

    testWidgets('goes back to the QR and forgets the text', (tester) async {
      // ARRANGE
      final server = FakeAuthServer();
      await openFallback(tester, server);
      await tester.enterText(find.byType(TextField), 'felig-beirt');

      // ACT
      await tester.tap(find.text('Vissza a QR-kódhoz'));
      await flush(tester);

      // ASSERT: uj keres, a mezo eltunt
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(QrCodeImage), findsOneWidget);
      expect(server.openedRequests, 2);
    });
  });
}
