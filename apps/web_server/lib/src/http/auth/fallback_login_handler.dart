import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/fallback_login_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/auth/browser_origin.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// `POST /api/auth/fallback-login`: tartalék belépés a weben jelszóval
/// vagy helyreállító kóddal (ADR 0051 D6, Addendum 6 N2, N3).
///
/// Siker: `200`, a fiók és a session cookie. Minden rossz szöveg ugyanaz
/// a `401`; a várakozás alatt `429` és `Retry-After`.
class FallbackLoginHandler {
  /// Handler a [service] fölött; az IP-korlát a [limiter].
  const FallbackLoginHandler({
    required FallbackLoginService service,
    required SessionService sessions,
    required RateLimiter limiter,
  }) : _service = service,
       _sessions = sessions,
       _limiter = limiter;

  final FallbackLoginService _service;
  final SessionService _sessions;
  final RateLimiter _limiter;

  /// A belépés.
  Future<Response> call(Request request) async {
    final browser = browserOriginOf(request);
    final limited = rateLimitedResponse(_limiter, browser.ip);
    if (limited != null) return limited;
    final FallbackLogin login;
    switch (await readDecodedBody(request, decodeFallbackLogin)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        login = value;
    }
    switch (await _service.signIn(login.secret, browser: browser)) {
      case Err(:final error):
        return authErrorResponse(error);
      case Ok(value: (:final account, :final session)):
        // Ha a böngészőnek már volt sessionje, az lezárul (L6).
        final previous = readCookie(request, sessionCookieName);
        if (previous != null) await _sessions.end(previous);
        return privateJsonResponse(
          encodeAccountInfo(account),
          cookies: [sessionCookie(session)],
        );
    }
  }
}
