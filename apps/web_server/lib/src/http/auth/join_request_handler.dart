import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/join_request_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/http/auth/client_ip.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// A fiók nélküli telefon végpontjai: a csatlakozási kérelem és az
/// állapota (ADR 0051 D3, Addendum 5 M3, M4).
class JoinRequestHandler {
  /// Handler a [service] fölött; a kérelmek a [limiter] alatt.
  const JoinRequestHandler({
    required JoinRequestService service,
    required RateLimiter limiter,
  }) : _service = service,
       _limiter = limiter;

  final JoinRequestService _service;
  final RateLimiter _limiter;

  /// `POST /api/auth/join-requests`: `201`, a telefon jegye.
  Future<Response> submit(Request request) async {
    final ip = clientIpOf(request);
    final limited = rateLimitedResponse(_limiter, ip);
    if (limited != null) return limited;
    switch (await readDecodedBody(request, decodeJoinRequest)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(value: final joinRequest):
        return switch (await _service.submit(joinRequest, ip: ip)) {
          Ok(:final value) => privateJsonResponse(
            encodeJoinTicket(value),
            statusCode: 201,
          ),
          Err(:final error) => authErrorResponse(error),
        };
    }
  }

  /// `POST …/{id}/status`: a kérelem állapota a lekérdező tokennel.
  Future<Response> status(Request request, String joinRequestId) async {
    switch (await readDecodedBody(request, decodeJoinStatusQuery)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(value: final statusToken):
        final status = await _service.status(
          joinRequestId,
          statusToken: statusToken,
        );
        return privateJsonResponse(encodeJoinRequestStatus(status));
    }
  }
}
