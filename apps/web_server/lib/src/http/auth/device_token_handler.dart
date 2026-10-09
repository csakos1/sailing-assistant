import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/http/auth/client_ip.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// Az eszköz-token végpontjai (ADR 0051 Addendum 3 K3, K6).
///
/// A tokenkérés nincs külön korlátozva: kihívás nélkül nem kérhető, a
/// kihívás pedig igen.
class DeviceTokenHandler {
  /// Handler a [service] fölött; a kihívások a [challengeLimiter] alatt.
  const DeviceTokenHandler({
    required DeviceTokenService service,
    required RateLimiter challengeLimiter,
  }) : _service = service,
       _challengeLimiter = challengeLimiter;

  final DeviceTokenService _service;
  final RateLimiter _challengeLimiter;

  /// `POST /api/auth/device-challenges`: `201`, a kihívás.
  Future<Response> challenge(Request request) async {
    final ip = clientIpOf(request);
    final limited = rateLimitedResponse(_challengeLimiter, ip);
    if (limited != null) return limited;
    switch (await readDecodedBody(request, decodeDeviceChallengeRequest)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(value: final deviceId):
        return _issued(await _service.issueChallenge(deviceId));
    }
  }

  /// `POST /api/auth/device-tokens`: `201`, a 15 perces token.
  Future<Response> token(Request request) async {
    switch (await readDecodedBody(request, decodeSignedDeviceRequest)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(:final value):
        return _issued(await _service.issueToken(value));
    }
  }

  static Response _issued(Result<IssuedSecret, ApiError> result) =>
      switch (result) {
        Ok(:final value) => privateJsonResponse(
          encodeIssuedSecret(value),
          statusCode: 201,
        ),
        Err(:final error) => apiErrorResponse(error),
      };
}
