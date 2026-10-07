import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phone/features/web_access/data/web_access_api_client.dart';
import 'package:phone/features/web_access/data/web_api_failure.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import '../web_access_fakes.dart';

void main() {
  late FakeWebServer server;
  late WebAccessApiClient client;

  setUp(() {
    server = FakeWebServer();
    client = WebAccessApiClient(server.client, origin: testOrigin);
  });

  group('requests', () {
    test('every call is a POST with the phone client header', () async {
      // Arrange
      server.routes[deviceChallengesPath] = (_) =>
          jsonResponse(issuedJson(testChallenge));

      // Act
      await client.issueDeviceChallenge(testDeviceId);

      // Assert
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.url.toString(), '$testOrigin$deviceChallengesPath');
      expect(request.headers[clientHeaderName], clientHeaderPhoneValue);
      expect(FakeWebServer.bodyOf(request), {'deviceId': testDeviceId});
      expect(request.headers.containsKey('authorization'), isFalse);
    });

    test('opening a login request sends the bearer token', () async {
      // Arrange
      final path = loginRequestOpenPath(testRequestId);
      server.routes[path] = (_) =>
          jsonResponse(encodeBrowserLoginDetails(sampleDetails));

      // Act
      final result = await client.openLoginRequest(
        testRequestId,
        challenge: testChallenge,
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(
        result,
        const Ok<BrowserLoginDetails, WebApiFailure>(sampleDetails),
      );
      final request = server.requests.single;
      expect(request.headers['authorization'], 'Bearer $testDeviceToken');
      expect(FakeWebServer.bodyOf(request), {'challenge': testChallenge});
    });
  });

  group('responses', () {
    test('an approval answered with 204 is a success', () async {
      // Arrange
      server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
          http.Response('', 204);

      // Act
      final result = await client.approveLoginRequest(
        testRequestId,
        SignedDeviceRequest(
          deviceId: testDeviceId,
          signature: FakeKeys.biometricSignature,
        ),
      );

      // Assert
      expect(result, isA<Ok<void, WebApiFailure>>());
    });

    test('a contract error becomes a server failure', () async {
      // Arrange
      server.routes[loginRequestApprovalPath(testRequestId)] = (_) =>
          errorResponse(const RequestExpired());

      // Act
      final result = await client.approveLoginRequest(
        testRequestId,
        SignedDeviceRequest(
          deviceId: testDeviceId,
          signature: FakeKeys.biometricSignature,
        ),
      );

      // Assert
      expect(
        result,
        isA<Err<void, WebApiFailure>>().having(
          (err) => err.error,
          'error',
          isA<WebServerFailure>().having(
            (failure) => failure.error,
            'api error',
            const RequestExpired(),
          ),
        ),
      );
    });

    test('a body that is not the contract is unreadable', () async {
      // Arrange
      server.routes[deviceTokensPath] = (_) => http.Response('<html>', 502);

      // Act
      final result = await client.issueDeviceToken(
        SignedDeviceRequest(
          deviceId: testDeviceId,
          challenge: testChallenge,
          signature: FakeKeys.silentSignature,
        ),
      );

      // Assert
      expect(
        result,
        isA<Err<IssuedSecret, WebApiFailure>>().having(
          (err) => err.error,
          'error',
          isA<WebUnreadableResponse>().having(
            (failure) => failure.statusCode,
            'status',
            502,
          ),
        ),
      );
    });

    test('a refused connection is a network failure', () async {
      // Arrange
      final failing = WebAccessApiClient(
        MockClient((_) async => throw http.ClientException('refused')),
        origin: testOrigin,
      );

      // Act
      final result = await failing.issueDeviceChallenge(testDeviceId);

      // Assert
      expect(
        result,
        isA<Err<IssuedSecret, WebApiFailure>>().having(
          (err) => err.error,
          'error',
          isA<WebNetworkFailure>(),
        ),
      );
    });

    test(
      'a request that never answers times out as a network failure',
      () async {
        // Arrange
        final hanging = WebAccessApiClient(
          MockClient((_) => Completer<http.Response>().future),
          origin: testOrigin,
          timeout: const Duration(milliseconds: 10),
        );

        // Act
        final result = await hanging.issueDeviceChallenge(testDeviceId);

        // Assert
        expect(
          result,
          isA<Err<IssuedSecret, WebApiFailure>>().having(
            (err) => err.error,
            'error',
            isA<WebNetworkFailure>(),
          ),
        );
      },
    );

    test('the enrollment result decodes the account and the codes', () async {
      // Arrange
      const account = AccountInfo(
        userId: 'user-1',
        name: 'Ákos',
        role: UserRole.owner,
      );
      server.routes[enrollmentsPath] = (_) => jsonResponse(
        encodeEnrollmentResult(
          const EnrollmentResult(
            account: account,
            deviceId: testDeviceId,
            recoveryCodes: ['AAAAA-BBBBB'],
          ),
        ),
        status: 201,
      );

      // Act
      final result = await client.enroll(
        EnrollmentRequest(
          token: testToken,
          publicKey: FakeKeys.signingKey,
          deviceKey: FakeKeys.deviceKey,
          deviceName: 'Pixel 8',
          model: 'Google Pixel 8',
          signature: FakeKeys.biometricSignature,
        ),
      );

      // Assert
      expect(result, isA<Ok<EnrollmentResult, WebApiFailure>>());
      final body = FakeWebServer.bodyOf(server.requests.single);
      expect(body['deviceName'], 'Pixel 8');
      expect(body['publicKey'], base64Encode(FakeKeys.signingKey));
    });
  });
}
