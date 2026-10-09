import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/account_info_of.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/auth/bearer_token.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// A belépett fiók és a kijelentkezés (ADR 0051 D5, Addendum 3 K6).
class AccountHandler {
  /// Handler a [sessions] és az eszköz-hitelesítés fölött.
  const AccountHandler({
    required SessionService sessions,
    required DeviceAuthenticator authenticateDevice,
  }) : _sessions = sessions,
       _authenticateDevice = authenticateDevice;

  final SessionService _sessions;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/me`: a fiók; a telefon eszköz-tokennel, a web
  /// sessionnel kérdez.
  ///
  /// Ha van `Authorization` fejléc, az dönt: egy hibás token nem esik
  /// vissza egy esetleges session cookie-ra.
  Future<Response> me(Request request) async {
    if (hasAuthorizationHeader(request)) {
      return switch (await _authenticateDevice(request)) {
        Ok(:final value) => privateJsonResponse(
          encodeAccountInfo(accountInfoOf(value.user)),
        ),
        Err(:final error) => apiErrorResponse(error),
      };
    }
    final token = readCookie(request, sessionCookieName);
    final user = token == null ? null : await _sessions.userOf(token);
    if (user == null) return apiErrorResponse(const NotAuthenticated());
    return privateJsonResponse(encodeAccountInfo(accountInfoOf(user)));
  }

  /// `POST /api/auth/logout`: `204`; a session a szerveren is törlődik, és
  /// a cookie is. Session nélkül is `204`.
  Future<Response> logout(Request request) async {
    final token = readCookie(request, sessionCookieName);
    if (token != null) await _sessions.end(token);
    return Response(
      204,
      headers: {
        'cache-control': 'no-store',
        'set-cookie': clearedCookie(sessionCookieName),
      },
    );
  }
}
