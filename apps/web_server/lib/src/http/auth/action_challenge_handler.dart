import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_action_service.dart';
import 'package:web_server/src/auth/rate_limiter.dart';
import 'package:web_server/src/http/auth/client_ip.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/auth/rate_limited_response.dart';

/// `POST /api/auth/action-challenges`: kihívás egy ujjlenyomatos
/// művelethez (ADR 0051 Addendum 5 M2); `201`, a kihívás.
class ActionChallengeHandler {
  /// Handler a [service] fölött, a [limiter] korláttal.
  const ActionChallengeHandler({
    required DeviceActionService service,
    required DeviceAuthenticator authenticateDevice,
    required RateLimiter limiter,
  }) : _service = service,
       _authenticateDevice = authenticateDevice,
       _limiter = limiter;

  final DeviceActionService _service;
  final DeviceAuthenticator _authenticateDevice;
  final RateLimiter _limiter;

  /// A kihívás kiadása.
  Future<Response> call(Request request) async {
    final limited = rateLimitedResponse(_limiter, clientIpOf(request));
    if (limited != null) return limited;
    return withDeviceCaller(
      request,
      _authenticateDevice,
      (caller) async => privateJsonResponse(
        encodeIssuedSecret(await _service.issueChallenge(caller.device)),
        statusCode: 201,
      ),
    );
  }
}
