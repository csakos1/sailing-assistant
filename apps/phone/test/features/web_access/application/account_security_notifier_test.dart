import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/application/account_security_notifier.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late ProviderContainer container;

  const prompt = BiometricPromptText(title: 'Teszt', cancel: 'Mégse');

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore(testAccount());
    serveDeviceTokens(server);
    serveActionChallenges(server);
    server.routes[accountSecurityPath] = (_) => securityResponse();
    server.routes[bannerPath] = (_) => bannerResponse();
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

  // A fiokot a teszt meg atallithatja, ezert a figyeles (es vele a fiok
  // betoltese) csak itt indul. Az autoDispose provider csak figyelve marad
  // eletben.
  Future<AccountSecurityLoad> load() async {
    container.listen(accountSecurityProvider, (_, _) {});
    await container.read(webAccountProvider.future);
    return container.read(accountSecurityProvider.future);
  }

  AccountSecurityNotifier notifier() =>
      container.read(accountSecurityProvider.notifier);

  List<String> signedLines() =>
      const LineSplitter().convert(utf8.decode(keys.signedMessages.last));

  test('the owner gets the security state', () async {
    // Act
    final loaded = await load();

    // Assert
    expect(
      loaded,
      const Ok<AccountSecurity?, Object?>(
        AccountSecurity(recoveryCodesLeft: 7),
      ),
    );
  });

  test('the crew has no fallback and asks nothing', () async {
    // Arrange
    store.account = testAccount(role: UserRole.crew);

    // Act
    final loaded = await load();

    // Assert
    expect(switch (loaded) {
      Ok(:final value) => value,
      Err() => 'error',
    }, isNull);
    expect(server.requestsTo(accountSecurityPath), isEmpty);
  });

  test('a new password is signed and the state reloads', () async {
    // Arrange
    server.routes[accountPasswordPath] = (_) => http.Response('', 204);
    await load();

    // Act
    final error = await notifier().setPassword(
      'hajo-lola-balaton',
      prompt: prompt,
    );
    await container.read(accountSecurityProvider.future);

    // Assert
    expect(error, isNull);
    expect(signedLines(), contains('setPassword'));
    expect(signedLines().last, '-');
    final body = FakeWebServer.bodyOf(
      server.requestsTo(accountPasswordPath).single,
    );
    expect(body['password'], 'hajo-lola-balaton');
    expect(server.requestsTo(accountSecurityPath), hasLength(2));
  });

  test('new codes come back once and the state reloads', () async {
    // Arrange
    server.routes[accountRecoveryCodesPath] = (_) => jsonResponse(
      encodeIssuedRecoveryCodes(const IssuedRecoveryCodes(['ABCDE-FGHIJ'])),
      status: 201,
    );
    await load();

    // Act
    final result = await notifier().regenerateRecoveryCodes(prompt: prompt);
    await container.read(accountSecurityProvider.future);

    // Assert
    expect(
      switch (result) {
        Ok(:final value) => value,
        Err() => null,
      },
      ['ABCDE-FGHIJ'],
    );
    expect(signedLines(), contains('regenerateRecoveryCodes'));
    expect(server.requestsTo(accountSecurityPath), hasLength(2));
  });

  test('a cancelled fingerprint sends no password', () async {
    // Arrange
    keys.biometricFailure = KeyOperationFailure.canceled;
    await load();

    // Act
    final error = await notifier().setPassword(
      'hajo-lola-balaton',
      prompt: prompt,
    );

    // Assert
    expect(error, isNotNull);
    expect(server.requestsTo(accountPasswordPath), isEmpty);
  });

  test('a revoked phone marks the home screen as revoked', () async {
    // Arrange
    server.routes[deviceChallengesPath] = (_) =>
        errorResponse(const DeviceRevoked());

    // Act
    await load();

    // Assert
    expect(container.read(webAccessStatusProvider).isRevoked, isTrue);
  });
}
