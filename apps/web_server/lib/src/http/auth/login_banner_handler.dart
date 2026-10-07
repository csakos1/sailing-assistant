import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/login_banner_service.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';

/// A szalag és a nyugtázás végpontjai (ADR 0051 Addendum 6 N6), eszköz-
/// tokennel.
class LoginBannerHandler {
  /// Handler a [service] fölött.
  const LoginBannerHandler({
    required LoginBannerService service,
    required DeviceAuthenticator authenticateDevice,
  }) : _service = service,
       _authenticateDevice = authenticateDevice;

  final LoginBannerService _service;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/banner`: a gyanús belépések és a függő kérelmek.
  Future<Response> banner(Request request) => withDeviceCaller(
    request,
    _authenticateDevice,
    (caller) async =>
        privateJsonResponse(encodeLoginBanner(await _service.banner(caller))),
  );

  /// `POST /api/auth/login-events/{id}/acknowledgement`: `204`.
  Future<Response> acknowledge(Request request, String eventId) =>
      withDeviceCaller(
        request,
        _authenticateDevice,
        (caller) async =>
            noContentOr(await _service.acknowledge(caller, eventId)),
      );
}
