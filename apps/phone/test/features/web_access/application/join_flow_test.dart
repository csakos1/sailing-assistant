import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/join_flow.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/pending_join.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late MemoryWebAccountStore store;
  late JoinFlow flow;

  const prompt = BiometricPromptText(
    title: 'Csatlakozás a Lola archívumához',
    cancel: 'Mégse',
  );

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    store = MemoryWebAccountStore();
    flow = JoinFlow(
      clientFor: (origin) => WebAccessApiClient(server.client, origin: origin),
      keys: keys.operations,
      readIdentity: () async =>
          (deviceName: 'Pixel 7a', model: 'Google Pixel 7a'),
      savePendingJoin: store.writePendingJoin,
    );
    server.routes[joinRequestsPath] = (_) => joinTicketResponse();
  });

  Future<Result<PendingJoin, WebAccessError>> run({String name = 'Gergő'}) =>
      flow.run(loginPayload(), name: name, prompt: prompt);

  // A hibak nem ertek-egyenloek, ezert a belsejuket hasonlitjuk.
  KeyOperationFailure failureOf(Result<PendingJoin, WebAccessError> result) {
    final error = (result as Err<PendingJoin, WebAccessError>).error;
    return (error as KeyOperationFailed).failure;
  }

  ApiError serverErrorOf(Result<PendingJoin, WebAccessError> result) {
    final error = (result as Err<PendingJoin, WebAccessError>).error;
    return ((error as ApiCallFailed).failure as WebServerFailure).error;
  }

  test('sends the request with fresh keys and keeps it as pending', () async {
    // Act
    final result = await run(name: '  Gergő ');

    // Assert
    final pending = (result as Ok<PendingJoin, WebAccessError>).value;
    expect(pending, testPendingJoin());
    expect(store.pendingJoin, pending);
    expect(keys.calls, [
      'delete',
      'create:signing',
      'create:device',
      'sign:biometric',
    ]);
    final body = FakeWebServer.bodyOf(server.requests.single);
    expect(body['name'], 'Gergő');
    expect(body['deviceName'], 'Pixel 7a');
    expect(body['model'], 'Google Pixel 7a');
  });

  test('signs the join message with both keys and the trimmed name', () async {
    // Act
    await run(name: ' Gergő');

    // Assert
    expect(
      keys.signedMessages.single,
      joinRequestMessage(
        origin: testOrigin,
        requestId: testRequestId,
        challenge: testChallenge,
        name: 'Gergő',
        publicKey: FakeKeys.signingKey,
        deviceKey: FakeKeys.deviceKey,
      ),
    );
  });

  test('a dismissed fingerprint sends nothing', () async {
    // Arrange
    keys.biometricFailure = KeyOperationFailure.canceled;

    // Act
    final result = await run();

    // Assert
    expect(failureOf(result), KeyOperationFailure.canceled);
    expect(server.requests, isEmpty);
    expect(store.pendingJoin, isNull);
  });

  test('an expired login request saves nothing', () async {
    // Arrange
    server.routes[joinRequestsPath] = (_) =>
        errorResponse(const RequestExpired());

    // Act
    final result = await run();

    // Assert
    expect(serverErrorOf(result), const RequestExpired());
    expect(store.pendingJoin, isNull);
  });

  test('too many requests pass the wait on', () async {
    // Arrange
    server.routes[joinRequestsPath] = (_) =>
        errorResponse(const TooManyAttempts(90));

    // Act
    final result = await run();

    // Assert
    expect(serverErrorOf(result), const TooManyAttempts(90));
  });

  test('a rejected request body saves nothing', () async {
    // Arrange
    server.routes[joinRequestsPath] = (_) => errorResponse(
      const MalformedRequest(
        DecodeError(path: r'$.publicKey', expected: 'unused key'),
      ),
    );

    // Act
    final result = await run();

    // Assert
    expect(serverErrorOf(result), isA<MalformedRequest>());
    expect(store.pendingJoin, isNull);
  });

  test('a key that cannot be created stops before signing', () async {
    // Arrange
    keys.createFailure = KeyOperationFailure.unavailable;

    // Act
    final result = await run();

    // Assert
    expect(failureOf(result), KeyOperationFailure.unavailable);
    expect(keys.calls, ['delete', 'create:signing']);
  });

  test('a name the server would refuse is a programming error', () {
    // Act and assert
    expect(() => run(name: '   '), throwsArgumentError);
  });
}
