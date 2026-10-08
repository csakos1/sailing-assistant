import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phone/features/web_access/application/authorized_call.dart';
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/signed_action_runner.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_key_operations.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late FakeKeys keys;
  late SignedActionRunner runner;

  const prompt = BiometricPromptText(
    title: 'Gergő jóváhagyása',
    cancel: 'Mégse',
  );

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    final client = WebAccessApiClient(server.client, origin: testOrigin);
    runner = SignedActionRunner(
      client: client,
      calls: AuthorizedCall(
        DeviceTokenSource(
          account: testAccount(),
          client: client,
          signSilently: keys.operations.signSilently,
          now: () => testNow,
        ),
      ),
      signWithBiometrics: keys.operations.signWithBiometrics,
    );
    serveDeviceTokens(server);
    server.routes[actionChallengesPath] = (_) =>
        jsonResponse(issuedJson(testChallenge), status: 201);
  });

  Future<Result<SignedAction, WebAccessError>> sign() => runner.sign(
    DeviceAction.revokeDevice,
    target: 'device-9',
    prompt: prompt,
  );

  test('signs the action message with the fingerprint key', () async {
    // Act
    final result = await sign();

    // Assert
    expect(
      result,
      Ok<SignedAction, WebAccessError>(
        SignedAction(
          challenge: testChallenge,
          signature: FakeKeys.biometricSignature,
        ),
      ),
    );
    final message = utf8.decode(keys.signedMessages.last);
    expect(message.split('\n'), [
      'foretack-action-v1',
      testOrigin,
      testDeviceId,
      testChallenge,
      'revokeDevice',
      'device-9',
    ]);
    expect(keys.prompts.single, prompt);
    expect(
      server.requestsTo(actionChallengesPath).single.headers['authorization'],
      'Bearer $testDeviceToken',
    );
  });

  test('a cancelled fingerprint returns the key failure', () async {
    // Arrange
    keys.biometricFailure = KeyOperationFailure.canceled;

    // Act
    final result = await sign();

    // Assert
    final error = (result as Err<SignedAction, WebAccessError>).error;
    expect(
      (error as KeyOperationFailed).failure,
      KeyOperationFailure.canceled,
    );
  });

  test('a failed challenge asks for no fingerprint', () async {
    // Arrange
    server.routes[actionChallengesPath] = (_) =>
        errorResponse(const TooManyAttempts(30));

    // Act
    final result = await sign();

    // Assert
    expect(result, isA<Err<SignedAction, WebAccessError>>());
    expect(keys.calls, isNot(contains('sign:biometric')));
  });
}
