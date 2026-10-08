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

  group('join requests', () {
    test('a join request is posted and answered with a ticket', () async {
      // Arrange
      server.routes[joinRequestsPath] = (_) => joinTicketResponse();
      final request = JoinRequest(
        requestId: testRequestId,
        challenge: testChallenge,
        name: 'Gergő',
        deviceName: 'Pixel 7a',
        model: 'Google Pixel 7a',
        publicKey: FakeKeys.signingKey,
        deviceKey: FakeKeys.deviceKey,
        signature: FakeKeys.biometricSignature,
      );

      // Act
      final result = await client.submitJoinRequest(request);

      // Assert
      final ticket = (result as Ok<JoinTicket, WebApiFailure>).value;
      expect(ticket.statusToken, testStatusToken);
      final sent = server.requests.single;
      expect(sent.headers[clientHeaderName], clientHeaderPhoneValue);
      expect(FakeWebServer.bodyOf(sent), encodeJoinRequest(request));
    });

    test('the status query sends only the status token', () async {
      // Arrange
      server.routes[joinRequestStatusPath(testJoinRequestId)] = (_) =>
          joinStatusResponse(JoinRequestState.pending);

      // Act
      final result = await client.joinRequestStatus(
        testJoinRequestId,
        statusToken: testStatusToken,
      );

      // Assert
      expect(
        result,
        const Ok<JoinRequestStatus, WebApiFailure>(
          JoinRequestStatus(state: JoinRequestState.pending),
        ),
      );
      expect(
        FakeWebServer.bodyOf(server.requests.single),
        {'statusToken': testStatusToken},
      );
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

  group('management calls', () {
    test('the account is read with a bearer GET and no body', () async {
      // Arrange
      server.routes[mePath] = (_) => meResponse(name: 'Ákos Új');

      // Act
      final result = await client.fetchAccount(deviceToken: testDeviceToken);

      // Assert
      expect(
        result,
        const Ok<AccountInfo, WebApiFailure>(
          AccountInfo(userId: 'user-1', name: 'Ákos Új', role: UserRole.owner),
        ),
      );
      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.headers['authorization'], 'Bearer $testDeviceToken');
      expect(request.headers[clientHeaderName], clientHeaderPhoneValue);
      expect(request.headers.containsKey('content-type'), isFalse);
      expect(request.body, isEmpty);
    });

    test('the banner and the sessions decode their lists', () async {
      // Arrange
      final login = testSuspiciousLogin();
      final session = testSession();
      server.routes[bannerPath] = (_) =>
          bannerResponse(suspicious: [login], pendingJoinRequests: 2);
      server.routes[sessionsPath] = (_) => sessionsResponse([session]);

      // Act
      final banner = await client.fetchBanner(deviceToken: testDeviceToken);
      final sessions = await client.listSessions(
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(
        banner,
        Ok<LoginBanner, WebApiFailure>(
          LoginBanner(suspicious: [login], pendingJoinRequests: 2),
        ),
      );
      expect(
        switch (sessions) {
          Ok(:final value) => value,
          Err() => null,
        },
        [session],
      );
    });

    test('ending a session is a DELETE answered with 204', () async {
      // Arrange
      server.routes[sessionPath('session-1')] = (_) => http.Response('', 204);

      // Act
      final result = await client.endSession(
        'session-1',
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(result, isA<Ok<void, WebApiFailure>>());
      expect(server.requests.single.method, 'DELETE');
    });

    test('acknowledging a login is a body-less POST', () async {
      // Arrange
      final path = loginEventAcknowledgementPath('event-1');
      server.routes[path] = (_) => http.Response('', 204);

      // Act
      final result = await client.acknowledgeLoginEvent(
        'event-1',
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(result, isA<Ok<void, WebApiFailure>>());
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.body, isEmpty);
      expect(request.headers[clientHeaderName], clientHeaderPhoneValue);
    });

    test('an action challenge is posted with the bearer token', () async {
      // Arrange
      server.routes[actionChallengesPath] = (_) =>
          jsonResponse(issuedJson(testChallenge), status: 201);

      // Act
      final result = await client.issueActionChallenge(
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(switch (result) {
        Ok(:final value) => value.value,
        Err() => null,
      }, testChallenge);
      final request = server.requests.single;
      expect(request.headers['authorization'], 'Bearer $testDeviceToken');
      expect(FakeWebServer.bodyOf(request), isEmpty);
    });
  });
}
