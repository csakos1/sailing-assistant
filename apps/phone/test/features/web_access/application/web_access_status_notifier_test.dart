import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/application/web_access_status.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late ProviderContainer container;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    server.routes[bannerPath] = (_) =>
        bannerResponse(suspicious: [testSuspiciousLogin()]);
    server.routes[mePath] = (_) => meResponse();
    container = ProviderContainer(
      overrides: [
        webAccountStoreProvider.overrideWithValue(store),
        pendingJoinStoreProvider.overrideWithValue(store),
        webHttpClientProvider.overrideWithValue(server.client),
        webKeyOperationsProvider.overrideWithValue(keys.operations),
        clockProvider.overrideWithValue(() => testNow),
      ],
    );
    addTearDown(container.dispose);
  });

  // A fiok betoltese az elso olvasas utan.
  Future<void> loadAccount() => container.read(webAccountProvider.future);

  WebAccessStatus statusOf() => container.read(webAccessStatusProvider);

  Future<void> refresh() async {
    await loadAccount();
    await container.read(webAccessStatusProvider.notifier).refresh();
  }

  group('refresh', () {
    test('shows the banner and keeps an unchanged account', () async {
      // Act
      await refresh();

      // Assert
      expect(statusOf().banner?.suspicious, [testSuspiciousLogin()]);
      expect(statusOf().isRevoked, isFalse);
      expect(store.account, testAccount());
    });

    test('a renamed account is saved with the same device', () async {
      // Arrange
      server.routes[mePath] = (_) => meResponse(name: 'Ákos Cs.');

      // Act
      await refresh();

      // Assert
      expect(store.account?.account.name, 'Ákos Cs.');
      expect(store.account?.deviceId, testDeviceId);
      expect(store.account?.origin, testOrigin);
      expect(statusOf().banner, isNotNull);
    });

    test('a revoked phone is marked as revoked', () async {
      // Arrange
      server.routes[deviceChallengesPath] = (_) =>
          errorResponse(const DeviceRevoked());

      // Act
      await refresh();

      // Assert
      expect(statusOf(), WebAccessStatus.revoked);
      expect(server.requestsTo(bannerPath), isEmpty);
    });

    test('a revoked phone stays revoked after a network error', () async {
      // Arrange
      server.routes[deviceChallengesPath] = (_) =>
          errorResponse(const DeviceRevoked());
      await refresh();
      server.routes[deviceChallengesPath] = (_) => http.Response('down', 502);

      // Act
      await refresh();

      // Assert
      expect(statusOf(), WebAccessStatus.revoked);
    });

    test('a failed account read keeps the fresh banner', () async {
      // Arrange
      server.routes[mePath] = (_) => http.Response('down', 502);

      // Act
      await refresh();

      // Assert
      expect(statusOf().banner?.suspicious, [testSuspiciousLogin()]);
    });

    test('an unreachable server shows nothing', () async {
      // Arrange
      server.routes[bannerPath] = (_) => http.Response('down', 502);

      // Act
      await refresh();

      // Assert
      expect(statusOf(), WebAccessStatus.none);
      expect(server.requestsTo(mePath), isEmpty);
    });

    test('without an account nothing is asked', () async {
      // Arrange
      store.account = null;

      // Act
      await refresh();

      // Assert
      expect(statusOf(), WebAccessStatus.none);
      expect(server.requests, isEmpty);
    });

    test('two refreshes at once share one request', () async {
      // Arrange
      await loadAccount();
      final notifier = container.read(webAccessStatusProvider.notifier);

      // Act
      await Future.wait([notifier.refresh(), notifier.refresh()]);

      // Assert
      expect(server.requestsTo(bannerPath), hasLength(1));
    });

    test('another account clears the shown banner', () async {
      // Arrange
      await refresh();

      // Act
      await container
          .read(webAccountProvider.notifier)
          .save(testAccount(origin: otherOrigin));

      // Assert
      expect(statusOf(), WebAccessStatus.none);
    });
  });

  group('actions', () {
    test('acknowledging a login refreshes the banner', () async {
      // Arrange
      final path = loginEventAcknowledgementPath('event-1');
      server.routes[path] = (_) => http.Response('', 204);
      await refresh();
      server.routes[bannerPath] = (_) => bannerResponse();

      // Act
      final error = await container
          .read(webAccessStatusProvider.notifier)
          .acknowledge('event-1');

      // Assert
      expect(error, isNull);
      expect(server.requestsTo(path), hasLength(1));
      expect(statusOf().banner?.suspicious, isEmpty);
    });

    test('a revoked phone on sign-out returns the error', () async {
      // Arrange
      await refresh();
      server.routes[sessionPath('session-9')] = (_) =>
          errorResponse(const DeviceRevoked());

      // Act
      final error = await container
          .read(webAccessStatusProvider.notifier)
          .endSession('session-9');

      // Assert
      expect(error, isNotNull);
      expect(statusOf(), WebAccessStatus.revoked);
    });
  });
}
