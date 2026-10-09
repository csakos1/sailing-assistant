import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/presentation/web_access_refresher.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  final statusPath = joinRequestStatusPath(testJoinRequestId);

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore()..pendingJoin = testPendingJoin();
    server.routes[statusPath] = (_) =>
        joinStatusResponse(JoinRequestState.pending);
  });

  Future<void> pumpRefresher(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webAccountStoreProvider.overrideWithValue(store),
          pendingJoinStoreProvider.overrideWithValue(store),
          webHttpClientProvider.overrideWithValue(server.client),
          webKeyOperationsProvider.overrideWithValue(keys.operations),
          clockProvider.overrideWithValue(() => testNow),
        ],
        child: MaterialApp(
          theme: foretackTheme,
          localizationsDelegates: phoneLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: WebAccessRefresher(child: Text('home')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // A platform eletciklus-uzenete, mint egy valodi hatterbe es vissza
  // valtasnal.
  Future<void> bringToForeground(WidgetTester tester) async {
    for (final state in [AppLifecycleState.paused, AppLifecycleState.resumed]) {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.lifecycle.name,
        SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
        (_) {},
      );
    }
  }

  testWidgets('an undecided request stays quiet on start', (tester) async {
    // Act
    await pumpRefresher(tester);

    // Assert
    expect(server.requestsTo(statusPath), hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
    expect(store.pendingJoin, testPendingJoin());
  });

  testWidgets('an approval seen on resume is announced', (tester) async {
    // Arrange
    await pumpRefresher(tester);
    server.routes[statusPath] = (_) =>
        joinStatusResponse(JoinRequestState.approved);

    // Act
    await bringToForeground(tester);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Csatlakoztál a Lola archívumához'), findsOneWidget);
    expect(store.account?.deviceId, 'device-7');
  });

  testWidgets('a refusal on start is announced and cleans up', (
    tester,
  ) async {
    // Arrange
    server.routes[statusPath] = (_) =>
        joinStatusResponse(JoinRequestState.notApproved);

    // Act
    await pumpRefresher(tester);

    // Assert
    expect(
      find.text('A csatlakozási kérelmet nem hagyták jóvá, vagy lejárt.'),
      findsOneWidget,
    );
    expect(store.pendingJoin, isNull);
    expect(keys.calls, ['delete']);
  });

  testWidgets('without a pending request nothing is asked', (tester) async {
    // Arrange
    store.pendingJoin = null;

    // Act
    await pumpRefresher(tester);

    // Assert
    expect(server.requests, isEmpty);
  });

  group('with an account', () {
    setUp(() {
      store
        ..pendingJoin = null
        ..account = testAccount();
      serveDeviceTokens(server);
      server.routes[bannerPath] = (_) =>
          bannerResponse(suspicious: [testSuspiciousLogin()]);
      server.routes[mePath] = (_) => meResponse();
    });

    testWidgets('the banner and the account are fetched on start', (
      tester,
    ) async {
      // Act
      await pumpRefresher(tester);

      // Assert
      expect(server.requestsTo(bannerPath), hasLength(1));
      expect(server.requestsTo(mePath), hasLength(1));
      expect(server.requestsTo(statusPath), isEmpty);
    });

    testWidgets('coming back to the foreground fetches again', (
      tester,
    ) async {
      // Arrange
      await pumpRefresher(tester);

      // Act
      await bringToForeground(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(server.requestsTo(bannerPath), hasLength(2));
    });
  });

  testWidgets('an approved join fetches the banner of the new account', (
    tester,
  ) async {
    // Arrange
    serveDeviceTokens(server);
    server.routes[bannerPath] = (_) => bannerResponse();
    server.routes[mePath] = (_) =>
        meResponse(userId: 'crew-1', name: 'Gergő', role: UserRole.crew);
    server.routes[statusPath] = (_) =>
        joinStatusResponse(JoinRequestState.approved);

    // Act
    await pumpRefresher(tester);

    // Assert
    expect(store.account?.deviceId, 'device-7');
    expect(server.requestsTo(bannerPath), hasLength(1));
  });
}
