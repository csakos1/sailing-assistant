import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:http/http.dart' as http;
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/features/web_access/presentation/join_pending_screen.dart';
import 'package:phone/features/web_access/presentation/qr_scan_screen.dart';
import 'package:phone/features/web_access/presentation/widgets/qr_camera_view.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late String nextCode;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    nextCode = encodeQrPayload(loginPayload());
    server.routes[deviceChallengesPath] = (_) =>
        jsonResponse(issuedJson(testChallenge));
    server.routes[deviceTokensPath] = (_) =>
        jsonResponse(issuedJson(testDeviceToken), status: 201);
    server.routes[loginRequestOpenPath(testRequestId)] = (_) =>
        jsonResponse(encodeBrowserLoginDetails(sampleDetails));
    server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
        http.Response('', 204);
  });

  // A kamera helyett egy gomb: a megnyomasa a `nextCode`-ot olvassa be.
  Widget fakeCamera({
    required bool isActive,
    required ValueChanged<String> onCode,
  }) => Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.only(top: 100),
      child: TextButton(
        onPressed: isActive ? () => onCode(nextCode) : null,
        child: Text(isActive ? 'scan' : 'paused'),
      ),
    ),
  );

  Future<void> pumpHost(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webAccountStoreProvider.overrideWithValue(store),
          pendingJoinStoreProvider.overrideWithValue(store),
          webHttpClientProvider.overrideWithValue(server.client),
          webKeyOperationsProvider.overrideWithValue(keys.operations),
          readDeviceIdentityProvider.overrideWithValue(
            () async => (deviceName: 'Pixel 8', model: 'Google Pixel 8'),
          ),
          qrCameraBuilderProvider.overrideWithValue(fakeCamera),
          clockProvider.overrideWithValue(() => testNow),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _Host(),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester, String code) async {
    nextCode = code;
    await tester.tap(find.text('scan'));
    await tester.pumpAndSettle();
  }

  testWidgets('a successful login closes with the browser details', (
    tester,
  ) async {
    // Arrange
    await pumpHost(tester);

    // Act
    await scan(tester, encodeQrPayload(loginPayload()));

    // Assert
    expect(find.text('result: Chrome'), findsOneWidget);
    expect(keys.prompts.single.title, 'Belépés a Foretack webre');
    expect(keys.prompts.single.subtitle, 'Chrome · Linux · Budapest, HU');
  });

  testWidgets('a foreign code shows the panel and Retry rescans', (
    tester,
  ) async {
    // Arrange
    await pumpHost(tester);

    // Act
    await scan(tester, 'https://example.com');

    // Assert
    expect(find.text('Ez nem Foretack-kód'), findsOneWidget);
    expect(find.text('paused'), findsOneWidget);

    // Act
    await tester.tap(find.text('Újra'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Ez nem Foretack-kód'), findsNothing);
    expect(find.text('scan'), findsOneWidget);
  });

  testWidgets('another server is named on the panel', (tester) async {
    // Arrange
    await pumpHost(tester);

    // Act
    await scan(tester, encodeQrPayload(loginPayload(origin: otherOrigin)));

    // Assert
    expect(find.text('Ez nem a te Foretack-szervered'), findsOneWidget);
    expect(find.textContaining('archivum.example.hu'), findsOneWidget);
  });

  testWidgets('a dismissed fingerprint prompt closes quietly', (tester) async {
    // Arrange
    keys.biometricFailure = KeyOperationFailure.canceled;
    await pumpHost(tester);

    // Act
    await scan(tester, encodeQrPayload(loginPayload()));

    // Assert
    expect(find.text('result: none'), findsOneWidget);
    expect(server.requestsTo(loginRequestApprovalPath(testRequestId)), isEmpty);
  });

  testWidgets('a revoked crew phone can clear itself to join again', (
    tester,
  ) async {
    // Arrange
    store.account = testAccount(role: UserRole.crew);
    server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
        errorResponse(const DeviceRevoked());
    await pumpHost(tester);
    await scan(tester, encodeQrPayload(loginPayload()));
    expect(find.text('Ez a telefon vissza lett vonva'), findsOneWidget);

    // Act
    await tester.tap(find.text('Csatlakozás kérése'));
    await tester.pumpAndSettle();

    // Assert
    expect(store.account, isNull);
    expect(keys.calls, contains('delete'));
    expect(find.text('scan'), findsOneWidget);
  });

  testWidgets('a revoked owner phone only offers Close', (tester) async {
    // Arrange
    server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
        errorResponse(const DeviceRevoked());
    await pumpHost(tester);

    // Act
    await scan(tester, encodeQrPayload(loginPayload()));

    // Assert
    expect(find.text('Csatlakozás kérése'), findsNothing);
    expect(find.text('Újra'), findsNothing);
    expect(find.text('Bezárás'), findsOneWidget);
  });

  group('joining', () {
    final statusPath = joinRequestStatusPath(testJoinRequestId);
    final sendButton = find.widgetWithText(FilledButton, 'Kérelem küldése');

    setUp(() {
      store.account = null;
      server.routes[joinRequestsPath] = (_) => joinTicketResponse();
      server.routes[statusPath] = (_) =>
          joinStatusResponse(JoinRequestState.pending);
    });

    Future<void> send(WidgetTester tester, String name) async {
      await tester.enterText(find.byType(TextField), name);
      await tester.pump();
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
    }

    testWidgets('a fresh phone sends a request and is let in on approval', (
      tester,
    ) async {
      // Arrange
      await pumpHost(tester);
      await scan(tester, encodeQrPayload(loginPayload()));
      expect(find.text('Csatlakozás a Lola archívumához'), findsOneWidget);
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

      // Act
      await send(tester, 'Gergő');

      // Assert
      expect(find.text('KÉRELEM ELKÜLDVE'), findsOneWidget);
      expect(find.text('Gergő'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('23 ó 30 p'), findsOneWidget);
      expect(store.pendingJoin, testPendingJoin());
      expect(keys.prompts.single.title, 'Csatlakozás a Lola archívumához');
      expect(keys.prompts.single.subtitle, 'localhost:8080');

      // Act
      server.routes[statusPath] = (_) =>
          joinStatusResponse(JoinRequestState.approved);
      await tester.pump(JoinPendingScreen.pollInterval);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(JoinPendingScreen), findsNothing);
      expect(find.text('Csatlakoztál a Lola archívumához'), findsOneWidget);
      expect(store.account?.account.role, UserRole.crew);
      expect(store.pendingJoin, isNull);
    });

    testWidgets('an expired code keeps the name for a one-touch retry', (
      tester,
    ) async {
      // Arrange
      server.routes[joinRequestsPath] = (_) =>
          errorResponse(const RequestExpired());
      await pumpHost(tester);
      await scan(tester, encodeQrPayload(loginPayload()));
      await send(tester, 'Gergő');
      expect(find.text('Lejárt QR-kód'), findsOneWidget);
      expect(
        find.text('Olvasd be újra a QR-kódot; a neved megmaradt.'),
        findsOneWidget,
      );

      // Act
      server.routes[joinRequestsPath] = (_) => joinTicketResponse();
      await tester.tap(find.text('Újra'));
      await tester.pumpAndSettle();
      await scan(tester, encodeQrPayload(loginPayload()));

      // Assert
      expect(find.byType(TextField), findsNothing);
      expect(find.text('KÉRELEM ELKÜLDVE'), findsOneWidget);
      expect(keys.prompts, hasLength(2));
      final sent = server.requestsTo(joinRequestsPath).last;
      expect(FakeWebServer.bodyOf(sent)['name'], 'Gergő');
    });

    testWidgets('a dismissed fingerprint stays on the form with the name', (
      tester,
    ) async {
      // Arrange
      keys.biometricFailure = KeyOperationFailure.canceled;
      await pumpHost(tester);
      await scan(tester, encodeQrPayload(loginPayload()));

      // Act
      await send(tester, 'Gergő');

      // Assert
      expect(find.text('Csatlakozás a Lola archívumához'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Gergő'), findsOneWidget);
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
      expect(server.requestsTo(joinRequestsPath), isEmpty);
    });

    testWidgets('a name the server would refuse blocks sending', (
      tester,
    ) async {
      // Arrange
      await pumpHost(tester);
      await scan(tester, encodeQrPayload(loginPayload()));

      // Act
      await tester.enterText(find.byType(TextField), 'G' * 41);
      await tester.pump();

      // Assert
      expect(find.text('1–40 karakter, sortörés nélkül'), findsOneWidget);
      expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);
    });

    testWidgets('a pending request reopens instead of sending a new one', (
      tester,
    ) async {
      // Arrange
      store.pendingJoin = testPendingJoin();
      await pumpHost(tester);

      // Act
      await scan(tester, encodeQrPayload(loginPayload()));

      // Assert
      expect(find.text('KÉRELEM ELKÜLDVE'), findsOneWidget);
      expect(server.requestsTo(joinRequestsPath), isEmpty);
      expect(server.requestsTo(statusPath), hasLength(1));
    });

    testWidgets('the pending screen pauses polling in the background', (
      tester,
    ) async {
      // Arrange
      Future<void> lifecycle(AppLifecycleState state) =>
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            SystemChannels.lifecycle.name,
            SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
            (_) {},
          );
      store.pendingJoin = testPendingJoin();
      await pumpHost(tester);
      await scan(tester, encodeQrPayload(loginPayload()));
      expect(server.requestsTo(statusPath), hasLength(1));

      // Act
      await lifecycle(AppLifecycleState.paused);
      await tester.pump(JoinPendingScreen.pollInterval * 3);

      // Assert
      expect(server.requestsTo(statusPath), hasLength(1));

      // Act
      await lifecycle(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Assert
      expect(server.requestsTo(statusPath), hasLength(2));
    });

    testWidgets('a refused request says so and drops the keys', (
      tester,
    ) async {
      // Arrange
      store.pendingJoin = testPendingJoin();
      server.routes[statusPath] = (_) =>
          joinStatusResponse(JoinRequestState.notApproved);
      await pumpHost(tester);

      // Act
      await scan(tester, encodeQrPayload(loginPayload()));

      // Assert
      expect(
        find.text('A kérelmet nem hagyták jóvá, vagy lejárt.'),
        findsOneWidget,
      );
      expect(store.pendingJoin, isNull);
      expect(keys.calls, contains('delete'));
    });
  });

  group('registration', () {
    final codes = List.generate(10, (index) => 'K${index}AAA-BBBBB');

    void answerEnrollment() {
      server.routes[enrollmentsPath] = (_) => jsonResponse(
        encodeEnrollmentResult(
          EnrollmentResult(
            account: const AccountInfo(
              userId: 'owner-1',
              name: 'Ákos',
              role: UserRole.owner,
            ),
            deviceId: 'device-9',
            recoveryCodes: codes,
          ),
        ),
        status: 201,
      );
    }

    testWidgets('a fresh phone registers and shows the codes once', (
      tester,
    ) async {
      // Arrange
      store.account = null;
      answerEnrollment();
      await pumpHost(tester);

      // Act
      await scan(tester, encodeQrPayload(enrollPayload()));

      // Assert
      expect(find.text('Telefon regisztrálva'), findsOneWidget);
      expect(find.text('localhost:8080'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(keys.prompts.single.subtitle, 'localhost:8080');

      // Act
      await tester.tap(find.text('Tovább a helyreállító kódokhoz'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('K0AAA-BBBBB'), findsOneWidget);
      expect(find.text('K9AAA-BBBBB'), findsOneWidget);

      // Act: a system back must not close the codes
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('K0AAA-BBBBB'), findsOneWidget);

      // Act
      await tester.tap(find.text('Elmentettem'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('result: none'), findsOneWidget);
      expect(store.account?.deviceId, 'device-9');
    });

    testWidgets('a registered phone asks before replacing its account', (
      tester,
    ) async {
      // Arrange
      final previous = store.account;
      answerEnrollment();
      await pumpHost(tester);

      // Act
      await scan(
        tester,
        encodeQrPayload(enrollPayload(origin: otherOrigin)),
      );

      // Assert
      expect(find.text('Fiók cseréje'), findsOneWidget);
      expect(find.textContaining('localhost:8080'), findsOneWidget);

      // Act
      await tester.tap(find.text('Mégse'));
      await tester.pumpAndSettle();

      // Assert
      expect(store.account, previous);
      expect(server.requests, isEmpty);
      expect(find.text('scan'), findsOneWidget);
    });
  });
}

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String _result = 'pending';

  Future<void> _open() async {
    final details = await QrScanScreen.open(context);
    if (!mounted) return;
    setState(() => _result = details?.browser ?? 'none');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () => unawaited(_open()),
          child: const Text('open'),
        ),
        Text('result: $_result'),
      ],
    ),
  );
}
