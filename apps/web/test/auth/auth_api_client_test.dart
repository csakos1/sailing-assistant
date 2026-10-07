import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/api/api_failure.dart';
import 'package:foretack_web/auth/auth_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

import 'auth_fixtures.dart';

void main() {
  final baseUri = Uri.parse('http://localhost:8080/');
  const owner = AccountInfo(
    userId: 'user-1',
    name: 'Ákos',
    role: UserRole.owner,
  );

  AuthApiClient clientAnswering(
    Future<http.Response> Function(http.Request request) handler,
  ) => AuthApiClient(MockClient(handler), baseUri: baseUri);

  T valueOf<T>(Result<T, ApiFailure> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Ok-t vartunk: $error'),
  };

  ApiFailure failureOf<T>(Result<T, ApiFailure> result) => switch (result) {
    Ok() => throw StateError('Err-t vartunk'),
    Err(:final error) => error,
  };

  group('fetchAccount', () {
    test('reads the account on 200', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return jsonResponse(encodeAccountInfo(owner));
      });

      // ACT
      final account = valueOf(await client.fetchAccount());

      // ASSERT
      expect(account, owner);
      expect(sent?.method, 'GET');
      expect(sent?.url, Uri.parse('http://localhost:8080/api/auth/me'));
    });

    test('treats 401 as signed out, not as a failure', () async {
      final client = clientAnswering(
        (request) async => errorResponse(const NotAuthenticated()),
      );

      final account = valueOf(await client.fetchAccount());

      expect(account, isNull);
    });

    test('reports a network failure', () async {
      final client = clientAnswering(
        (request) async => throw http.ClientException('offline'),
      );

      final failure = failureOf(await client.fetchAccount());

      expect(failure, isA<NetworkFailure>());
    });
  });

  group('signOut', () {
    test('posts with the client header and accepts 204', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return http.Response('', 204);
      });

      // ACT
      final result = await client.signOut();

      // ASSERT
      expect(result, isA<Ok<void, ApiFailure>>());
      expect(sent?.method, 'POST');
      expect(sent?.url.path, logoutPath);
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
    });

    test('reports a server error', () async {
      final client = clientAnswering(
        (request) async => errorResponse(const InternalError()),
      );

      final failure = failureOf(await client.signOut());

      expect(failure, isA<ServerFailure>());
    });
  });

  group('login requests', () {
    test('opens a request with the client header', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return ticketResponse(1);
      });

      // ACT
      final ticket = valueOf(await client.openLoginRequest());

      // ASSERT
      expect(ticket.requestId, requestIdOf(1));
      expect(ticket.qrText, 'foretack-login:v1:teszt-1');
      expect(sent?.method, 'POST');
      expect(sent?.url.path, loginRequestsPath);
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
    });

    test('polls the request by its id', () async {
      // ARRANGE
      Uri? requested;
      final client = clientAnswering((request) async {
        requested = request.url;
        return statusResponse(LoginRequestState.opened);
      });

      // ACT
      final status = valueOf(await client.pollLoginRequest(requestIdOf(2)));

      // ASSERT
      expect(status.state, LoginRequestState.opened);
      expect(requested?.path, loginRequestPollPath(requestIdOf(2)));
    });
  });

  group('signInWithSecret', () {
    test('sends the secret as JSON and reads the account', () async {
      // ARRANGE
      http.Request? sent;
      final client = clientAnswering((request) async {
        sent = request;
        return jsonResponse(encodeAccountInfo(owner));
      });

      // ACT
      final account = valueOf(
        await client.signInWithSecret('nagyon-titkos-jelszo'),
      );

      // ASSERT
      expect(account, owner);
      expect(sent?.url.path, fallbackLoginPath);
      expect(sent?.headers[clientHeaderName], clientHeaderWebValue);
      expect(jsonDecode(sent?.body ?? ''), {
        'secret': 'nagyon-titkos-jelszo',
      });
    });

    test('passes the rejection and the wait through', () async {
      // ARRANGE
      var calls = 0;
      final client = clientAnswering((request) async {
        calls++;
        return calls == 1
            ? errorResponse(const NotAuthenticated())
            : errorResponse(const TooManyAttempts(240));
      });

      // ACT
      final rejected = failureOf(await client.signInWithSecret('rossz'));
      final limited = failureOf(await client.signInWithSecret('rossz'));

      // ASSERT
      expect(
        rejected,
        isA<ServerFailure>().having(
          (failure) => failure.error,
          'error',
          const NotAuthenticated(),
        ),
      );
      expect(
        limited,
        isA<ServerFailure>().having(
          (failure) => failure.error,
          'error',
          const TooManyAttempts(240),
        ),
      );
    });
  });
}
