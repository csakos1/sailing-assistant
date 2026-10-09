import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/enrollment_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/http/auth/client_ip.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// `POST /api/auth/enrollments`: az `owner` telefonjának regisztrációja
/// (ADR 0051 D3, Addendum 3 K6); `201`, a fiók, az eszköz és a kódok.
class EnrollmentHandler {
  /// Handler a [service] fölött, a [limiter] korláttal.
  const EnrollmentHandler({
    required EnrollmentService service,
    required RateLimiter limiter,
  }) : _service = service,
       _limiter = limiter;

  final EnrollmentService _service;
  final RateLimiter _limiter;

  /// A regisztráció.
  Future<Response> call(Request request) async {
    final limited = rateLimitedResponse(_limiter, clientIpOf(request));
    if (limited != null) return limited;
    switch (await readDecodedBody(request, decodeEnrollmentRequest)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(value: final enrollment):
        return switch (await _service.enroll(enrollment)) {
          Ok(:final value) => privateJsonResponse(
            encodeEnrollmentResult(value),
            statusCode: 201,
          ),
          Err(:final error) => apiErrorResponse(error),
        };
    }
  }
}
