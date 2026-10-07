import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:http/http.dart' as http;
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
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
          webHttpClientProvider.overrideWithValue(server.client),
          webKeyOperationsProvider.overrideWithValue(keys.operations),
          readDeviceIdentityProvider.overrideWithValue(
            () async => (deviceName: 'Pixel 8', model: 'Google Pixel 8'),
          ),
          qrCameraBuilderProvider.overrideWithValue(fakeCamera),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 7, 11)),
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
