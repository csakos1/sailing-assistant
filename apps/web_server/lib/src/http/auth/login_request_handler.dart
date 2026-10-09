import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/login_request_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/auth/session_service.dart';
import 'package:web_server/src/http/auth/auth_cookies.dart';
import 'package:web_server/src/http/auth/browser_origin.dart';
import 'package:web_server/src/http/auth/client_ip.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// A QR-belépés végpontjai (ADR 0051 D4, Addendum 3 K5, K6).
///
/// A web nyit és kérdez (kötő-cookie-val), a telefon megnyit (eszköz-
/// tokennel) és jóváhagy (aláírással).
class LoginRequestHandler {
  /// Handler a [service] fölött.
  const LoginRequestHandler({
    required LoginRequestService service,
    required SessionService sessions,
    required DeviceAuthenticator authenticateDevice,
    required RateLimiter createLimiter,
    required RateLimiter openLimiter,
    required RateLimiter approvalLimiter,
  }) : _service = service,
       _sessions = sessions,
       _authenticateDevice = authenticateDevice,
       _createLimiter = createLimiter,
       _openLimiter = openLimiter,
       _approvalLimiter = approvalLimiter;

  final LoginRequestService _service;
  final SessionService _sessions;
  final DeviceAuthenticator _authenticateDevice;
  final RateLimiter _createLimiter;
  final RateLimiter _openLimiter;
  final RateLimiter _approvalLimiter;

  /// `POST /api/auth/login-requests`: `201`, a jegy és a kötő-cookie.
  Future<Response> create(Request request) async {
    final origin = browserOriginOf(request);
    final limited = rateLimitedResponse(_createLimiter, origin.ip);
    if (limited != null) return limited;
    final (:ticket, :binding) = await _service.create(origin);
    return privateJsonResponse(
      encodeLoginRequestTicket(ticket),
      statusCode: 201,
      cookies: [loginCookie(binding)],
    );
  }

  /// `POST …/{id}/poll`: az állapot; a beváltáskor a session cookie is.
  ///
  /// Ha a böngészőnek már volt sessionje, az a beváltáskor lezárul, hogy ne
  /// maradjon árva sor a munkamenetek között.
  Future<Response> poll(Request request, String requestId) async {
    final (:status, :session) = await _service.poll(
      requestId,
      binding: readCookie(request, loginCookieName),
      browser: browserOriginOf(request),
    );
    final previous = readCookie(request, sessionCookieName);
    if (session != null && previous != null) await _sessions.end(previous);
    return privateJsonResponse(
      encodeLoginRequestStatus(status),
      cookies: [
        if (session != null) ...[
          sessionCookie(session),
          clearedCookie(loginCookieName),
        ],
      ],
    );
  }

  /// `POST …/{id}/open`: a kérő böngésző leírása a telefonnak.
  Future<Response> open(Request request, String requestId) async {
    final limited = rateLimitedResponse(_openLimiter, clientIpOf(request));
    if (limited != null) return limited;
    // Csak regisztrált, aktív telefon nyithat meg kérést; hogy melyik, az
    // a megnyitásnál nem számít (L6).
    if (await _authenticateDevice(request) case Err(:final error)) {
      return apiErrorResponse(error);
    }
    final String challenge;
    switch (await readDecodedBody(request, decodeLoginRequestOpening)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        challenge = value;
    }
    final result = await _service.open(requestId, challenge: challenge);
    return switch (result) {
      Ok(:final value) => privateJsonResponse(encodeBrowserLoginDetails(value)),
      Err(:final error) => apiErrorResponse(error),
    };
  }

  /// `POST …/{id}/approval`: `204`, ha a jóváhagyás érvényes.
  Future<Response> approve(Request request, String requestId) async {
    final phoneIp = clientIpOf(request);
    final limited = rateLimitedResponse(_approvalLimiter, phoneIp);
    if (limited != null) return limited;
    switch (await readDecodedBody(request, decodeSignedDeviceRequest)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        final error = await _service.approve(
          requestId,
          approval: value,
          phoneIp: phoneIp,
        );
        return error == null ? Response(204) : apiErrorResponse(error);
    }
  }
}
