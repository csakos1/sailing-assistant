import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late WebAccessApiClient client;
  late AuthorizedCall calls;

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    client = WebAccessApiClient(server.client, origin: testOrigin);
    calls = AuthorizedCall(
      DeviceTokenSource(
        account: testAccount(),
        client: client,
        signSilently: keys.operations.signSilently,
        now: () => testNow,
      ),
    );
    serveDeviceTokens(server);
  });

  Future<Result<AccountInfo, WebAccessError>> fetchAccount() =>
      calls.run((token) => client.fetchAccount(deviceToken: token));

  test('a call gets a token once and is answered', () async {
    // Arrange
    server.routes[mePath] = (_) => meResponse();

    // Act
    final first = await fetchAccount();
    final second = await fetchAccount();

    // Assert
    expect(first, isA<Ok<AccountInfo, WebAccessError>>());
    expect(second, isA<Ok<AccountInfo, WebAccessError>>());
    expect(server.requestsTo(deviceTokensPath), hasLength(1));
    expect(server.requestsTo(mePath), hasLength(2));
  });

  test('a 401 drops the token and retries once with a new one', () async {
    // Arrange
    var answered = 0;
    server.routes[mePath] = (_) => answered++ == 0
        ? errorResponse(const NotAuthenticated())
        : meResponse();

    // Act
    final result = await fetchAccount();

    // Assert
    expect(result, isA<Ok<AccountInfo, WebAccessError>>());
    expect(server.requestsTo(deviceTokensPath), hasLength(2));
    expect(server.requestsTo(mePath), hasLength(2));
  });

  test('a second 401 is returned, not retried again', () async {
    // Arrange
    server.routes[mePath] = (_) => errorResponse(const NotAuthenticated());

    // Act
    final result = await fetchAccount();

    // Assert
    final error = (result as Err<AccountInfo, WebAccessError>).error;
    final failure = (error as ApiCallFailed).failure;
    expect((failure as WebServerFailure).error, const NotAuthenticated());
    expect(server.requestsTo(mePath), hasLength(2));
  });

  test('a revoked phone fails already at the token', () async {
    // Arrange
    server.routes[deviceChallengesPath] = (_) =>
        errorResponse(const DeviceRevoked());

    // Act
    final result = await fetchAccount();

    // Assert
    final error = (result as Err<AccountInfo, WebAccessError>).error;
    final failure = (error as ApiCallFailed).failure;
    expect((failure as WebServerFailure).error, const DeviceRevoked());
    expect(server.requestsTo(mePath), isEmpty);
  });

  test('a lost device key fails without a request', () async {
    // Arrange
    keys.silentFailure = KeyOperationFailure.keyMissing;

    // Act
    final result = await fetchAccount();

    // Assert
    final error = (result as Err<AccountInfo, WebAccessError>).error;
    expect(
      (error as KeyOperationFailed).failure,
      KeyOperationFailure.keyMissing,
    );
    expect(server.requestsTo(mePath), isEmpty);
  });
}
