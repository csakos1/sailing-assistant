import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/auth/bearer_token.dart';
import 'package:web_server/src/http/auth/client_ip.dart';

import 'auth_harness.dart';

Request _request({
  Map<String, String> headers = const {},
  String? remoteIp,
}) => Request(
  'GET',
  Uri.parse('https://archivum.example.hu/api/auth/me'),
  headers: headers,
  context: {
    if (remoteIp != null)
      'shelf.io.connection_info': FakeConnectionInfo(remoteIp),
  },
);

void main() {
  group('clientIpOf', () {
    test('takes the last forwarded address behind the local proxy', () {
      final request = _request(
        remoteIp: '127.0.0.1',
        headers: {'x-forwarded-for': '10.0.0.1, 203.0.113.7'},
      );

      expect(clientIpOf(request), '203.0.113.7');
    });

    test('ignores the forwarded header from a remote address', () {
      final request = _request(
        remoteIp: '198.51.100.20',
        headers: {'x-forwarded-for': '203.0.113.7'},
      );

      expect(clientIpOf(request), '198.51.100.20');
    });

    test('ignores a forwarded value that is not an address', () {
      final request = _request(
        remoteIp: '127.0.0.1',
        headers: {'x-forwarded-for': '<script>'},
      );

      expect(clientIpOf(request), '127.0.0.1');
    });

    test('names an unknown connection', () {
      expect(clientIpOf(_request()), unknownClientIp);
    });
  });

  group('readCookie', () {
    test('finds a cookie among others', () {
      final request = _request(
        headers: {'cookie': 'a=1; $sessionCookieName=abc_-1; b=2'},
      );

      expect(readCookie(request, sessionCookieName), 'abc_-1');
      expect(readCookie(request, loginCookieName), isNull);
    });

    test('treats an empty value as missing', () {
      final request = _request(headers: {'cookie': '$sessionCookieName='});

      expect(readCookie(request, sessionCookieName), isNull);
    });
  });

  group('bearerTokenOf', () {
    test('reads a base64url bearer token', () {
      final request = _request(headers: {'authorization': 'Bearer ab-_9'});

      expect(bearerTokenOf(request), 'ab-_9');
    });

    test('refuses other schemes and characters', () {
      for (final header in ['Basic YTpi', 'Bearer a b', 'Bearer a=']) {
        final request = _request(headers: {'authorization': header});
        expect(bearerTokenOf(request), isNull, reason: header);
      }
    });
  });
}
