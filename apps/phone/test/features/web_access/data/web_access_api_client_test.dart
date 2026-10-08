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

  group('crew and account calls', () {
    final action = SignedAction(
      challenge: testChallenge,
      signature: FakeKeys.biometricSignature,
    );

    T valueOf<T>(Result<T, WebApiFailure> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('$error'),
    };

    test('the join requests and the members decode their lists', () async {
      // Arrange
      final request = testPendingRequest();
      final member = testMember();
      server.routes[joinRequestsPath] = (_) => joinRequestsResponse([request]);
      server.routes[membersPath] = (_) => membersResponse([member]);

      // Act
      final requests = await client.listJoinRequests(
        deviceToken: testDeviceToken,
      );
      final members = await client.listMembers(deviceToken: testDeviceToken);

      // Assert
      expect(valueOf(requests), [request]);
      expect(valueOf(members), [member]);
      expect(server.requests.map((request) => request.method), [
        'GET',
        'GET',
      ]);
    });

    test('an approval carries the member and the signed action', () async {
      // Arrange
      final path = joinRequestApprovalPath('join-1');
      server.routes[path] = (_) => jsonResponse(encodeMemberInfo(testMember()));

      // Act
      final result = await client.approveJoinRequest(
        'join-1',
        JoinApproval(memberId: 'user-2', action: action),
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(valueOf(result), testMember());
      final body = FakeWebServer.bodyOf(server.requests.single);
      expect(body['memberId'], 'user-2');
      expect(body['challenge'], testChallenge);
      expect(body['signature'], base64Encode(FakeKeys.biometricSignature));
    });

    test('a rejection is a body-less POST answered with 204', () async {
      // Arrange
      final path = joinRequestRejectionPath('join-1');
      server.routes[path] = (_) => http.Response('', 204);

      // Act
      final result = await client.rejectJoinRequest(
        'join-1',
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(result, isA<Ok<void, WebApiFailure>>());
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.body, isEmpty);
    });

    test('revoking and removing post the signed action', () async {
      // Arrange
      server.routes[deviceRevocationPath('device-2')] = (_) =>
          http.Response('', 204);
      server.routes[memberRemovalPath('user-2')] = (_) =>
          http.Response('', 204);

      // Act
      final revoked = await client.revokeDevice(
        'device-2',
        action,
        deviceToken: testDeviceToken,
      );
      final removed = await client.removeMember(
        'user-2',
        action,
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(revoked, isA<Ok<void, WebApiFailure>>());
      expect(removed, isA<Ok<void, WebApiFailure>>());
      for (final request in server.requests) {
        expect(request.headers['content-type'], startsWith('application/json'));
        expect(FakeWebServer.bodyOf(request)['challenge'], testChallenge);
      }
    });

    test('a 410 on a decision comes back as the server error', () async {
      // Arrange
      server.routes[deviceRevocationPath('device-2')] = (_) =>
          errorResponse(const RequestExpired());

      // Act
      final result = await client.revokeDevice(
        'device-2',
        action,
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(switch (result) {
        Err(error: WebServerFailure(:final error)) => error,
        _ => null,
      }, const RequestExpired());
    });

    test('renaming returns the account with the new name', () async {
      // Arrange
      server.routes[accountNamePath] = (_) => meResponse(name: 'Ákos Cs.');

      // Act
      final result = await client.renameAccount(
        'Ákos Cs.',
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(valueOf(result).name, 'Ákos Cs.');
      expect(FakeWebServer.bodyOf(server.requests.single), {
        'name': 'Ákos Cs.',
      });
    });

    test('the security state, the password and the codes', () async {
      // Arrange
      final generatedAt = DateTime.utc(2026, 3, 2, 18, 40);
      server.routes[accountSecurityPath] = (_) =>
          securityResponse(recoveryCodesGeneratedAt: generatedAt);
      server.routes[accountPasswordPath] = (_) => http.Response('', 204);
      server.routes[accountRecoveryCodesPath] = (_) => jsonResponse(
        encodeIssuedRecoveryCodes(const IssuedRecoveryCodes(['ABCDE-FGHIJ'])),
        status: 201,
      );

      // Act
      final security = await client.fetchAccountSecurity(
        deviceToken: testDeviceToken,
      );
      final password = await client.setPassword(
        PasswordChange(password: 'hajo-lola-balaton', action: action),
        deviceToken: testDeviceToken,
      );
      final codes = await client.regenerateRecoveryCodes(
        action,
        deviceToken: testDeviceToken,
      );

      // Assert
      expect(valueOf(security).recoveryCodesGeneratedAt, generatedAt);
      expect(password, isA<Ok<void, WebApiFailure>>());
      expect(valueOf(codes).codes, ['ABCDE-FGHIJ']);
      final passwordBody = FakeWebServer.bodyOf(server.requests[1]);
      expect(passwordBody['password'], 'hajo-lola-balaton');
    });
  });
}
