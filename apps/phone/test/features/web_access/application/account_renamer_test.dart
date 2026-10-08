import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/account_renamer.dart';
import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:race_archive_api/race_archive_api.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late List<WebAccount> saved;
  late AccountRenamer rename;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    saved = [];
    final client = WebAccessApiClient(server.client, origin: testOrigin);
    rename = AccountRenamer(
      calls: AuthorizedCall(
        DeviceTokenSource(
          account: testAccount(),
          client: client,
          signSilently: keys.operations.signSilently,
          now: () => testNow,
        ),
      ),
      client: client,
      saveAccount: (account) async => saved.add(account),
    );
    serveDeviceTokens(server);
  });

  test('saves the new name with the same server and device', () async {
    // Arrange
    server.routes[accountNamePath] = (_) => meResponse(name: 'Ákos Cs.');

    // Act
    final error = await rename('Ákos Cs.');

    // Assert
    expect(error, isNull);
    expect(saved.single.account.name, 'Ákos Cs.');
    expect(saved.single.origin, testOrigin);
    expect(saved.single.deviceId, testDeviceId);
    expect(keys.calls, isNot(contains('sign:biometric')));
  });

  test('keeps the account when the server refuses', () async {
    // Arrange
    server.routes[accountNamePath] = (_) => errorResponse(
      const MalformedRequest(DecodeError(path: r'$.name', expected: 'name')),
    );

    // Act
    final error = await rename('Ákos Cs.');

    // Assert
    expect(error, isA<ApiCallFailed>());
    expect(saved, isEmpty);
  });
}
