import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:phone/features/web_access/application/device_token_source.dart';
import 'package:phone/features/web_access/application/qr_login_flow.dart';
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
  late DateTime now;
  late DeviceTokenSource tokens;
  late QrLoginFlow flow;

  const prompt = BiometricPromptText(title: 'Belépés', cancel: 'Mégse');

  setUp(() {
    server = FakeWebServer();
    keys = FakeKeys();
    now = DateTime.utc(2026, 10, 7, 11);
    final client = WebAccessApiClient(server.client, origin: testOrigin);
    tokens = DeviceTokenSource(
      account: testAccount(),
      client: client,
      signSilently: keys.operations.signSilently,
      now: () => now,
    );
    flow = QrLoginFlow(
      client: client,
      tokens: tokens,
      signWithBiometrics: keys.operations.signWithBiometrics,
    );
    server.routes[deviceChallengesPath] = (_) =>
        jsonResponse(issuedJson(testChallenge));
    server.routes[deviceTokensPath] = (_) =>
        jsonResponse(issuedJson(testDeviceToken), status: 201);
    server.routes[loginRequestOpenPath(testRequestId)] = (_) =>
        jsonResponse(encodeBrowserLoginDetails(sampleDetails));
    server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
        http.Response('', 204);
  });

  Future<Result<BrowserLoginDetails, WebAccessError>> run() =>
      flow.run(loginPayload(), promptOf: (_) => prompt);

  group('QrLoginFlow', () {
    test('opens, signs with the fingerprint and approves', () async {
      // Act
      final result = await run();

      // Assert
      expect(
        result,
        const Ok<BrowserLoginDetails, WebAccessError>(sampleDetails),
      );
      expect(keys.calls, ['sign:silent', 'sign:biometric']);
      expect(
        keys.signedMessages.last,
        loginApprovalMessage(
          origin: testOrigin,
          requestId: testRequestId,
          challenge: testChallenge,
          deviceId: testDeviceId,
        ),
      );
      final approval = FakeWebServer.bodyOf(
        server.requestsTo(loginRequestApprovalPath(testRequestId)).single,
      );
      expect(approval['deviceId'], testDeviceId);
    });

    test('the prompt shows the requesting browser', () async {
      // Arrange
      BrowserLoginDetails? shown;

      // Act
      await flow.run(
        loginPayload(),
        promptOf: (details) {
          shown = details;
          return prompt;
        },
      );

      // Assert
      expect(shown, sampleDetails);
      expect(keys.prompts.single, prompt);
    });

    test('signs the device token with the silent key', () async {
      // Act
      await run();

      // Assert
      expect(
        keys.signedMessages.first,
        deviceTokenMessage(
          origin: testOrigin,
          deviceId: testDeviceId,
          challenge: testChallenge,
        ),
      );
      final opening = server
          .requestsTo(loginRequestOpenPath(testRequestId))
          .single;
      expect(opening.headers['authorization'], 'Bearer $testDeviceToken');
    });

    test('a stale token is renewed once after a 401', () async {
      // Arrange
      var openings = 0;
      server.routes[loginRequestOpenPath(testRequestId)] = (_) {
        openings++;
        return openings == 1
            ? errorResponse(const NotAuthenticated())
            : jsonResponse(encodeBrowserLoginDetails(sampleDetails));
      };

      // Act
      final result = await run();

      // Assert
      expect(result, isA<Ok<BrowserLoginDetails, WebAccessError>>());
      expect(server.requestsTo(deviceTokensPath), hasLength(2));
    });

    test('a second 401 gives up', () async {
      // Arrange
      server.routes[loginRequestOpenPath(testRequestId)] = (_) =>
          errorResponse(const NotAuthenticated());

      // Act
      final result = await run();

      // Assert
      expect(
        server.requestsTo(loginRequestOpenPath(testRequestId)),
        hasLength(2),
      );
      expect(result, isA<Err<BrowserLoginDetails, WebAccessError>>());
      expect(keys.calls, isNot(contains('sign:biometric')));
    });

    test('an expired request stops before the fingerprint', () async {
      // Arrange
      server.routes[loginRequestOpenPath(testRequestId)] = (_) =>
          errorResponse(const RequestExpired());

      // Act
      final result = await run();

      // Assert
      final error = (result as Err<BrowserLoginDetails, WebAccessError>).error;
      final failure = (error as ApiCallFailed).failure;
      expect((failure as WebServerFailure).error, const RequestExpired());
      expect(keys.calls, isNot(contains('sign:biometric')));
    });

    test('a dismissed prompt does not approve', () async {
      // Arrange
      keys.biometricFailure = KeyOperationFailure.canceled;

      // Act
      final result = await run();

      // Assert
      final error = (result as Err<BrowserLoginDetails, WebAccessError>).error;
      expect(
        (error as KeyOperationFailed).failure,
        KeyOperationFailure.canceled,
      );
      expect(
        server.requestsTo(loginRequestApprovalPath(testRequestId)),
        isEmpty,
      );
    });

    test('a revoked phone is refused at approval', () async {
      // Arrange
      server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
          errorResponse(const DeviceRevoked());

      // Act
      final result = await run();

      // Assert
      final error = (result as Err<BrowserLoginDetails, WebAccessError>).error;
      final failure = (error as ApiCallFailed).failure;
      expect((failure as WebServerFailure).error, const DeviceRevoked());
    });
  });

  group('DeviceTokenSource', () {
    test('reuses a token until a minute before it expires', () async {
      // Act
      await tokens.token();
      now = DateTime.utc(2026, 10, 7, 11, 58, 59);
      await tokens.token();
      now = DateTime.utc(2026, 10, 7, 11, 59);
      await tokens.token();

      // Assert
      expect(server.requestsTo(deviceTokensPath), hasLength(2));
    });

    test('invalidate forces a new token', () async {
      // Act
      await tokens.token();
      tokens.invalidate();
      await tokens.token();

      // Assert
      expect(server.requestsTo(deviceTokensPath), hasLength(2));
    });

    test('a missing device key is reported as a key failure', () async {
      // Arrange
      keys.silentFailure = KeyOperationFailure.keyMissing;

      // Act
      final result = await tokens.token();

      // Assert
      final error = (result as Err<String, WebAccessError>).error;
      expect(
        (error as KeyOperationFailed).failure,
        KeyOperationFailure.keyMissing,
      );
      expect(server.requestsTo(deviceTokensPath), isEmpty);
    });
  });
}
