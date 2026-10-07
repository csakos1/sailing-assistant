import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/auth/member_service.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// A tagok és az eszközeik végpontjai (ADR 0051 Addendum 5 M7): lista,
/// eszköz visszavonása, tag eltávolítása.
class MemberHandler {
  /// Handler a [service] fölött.
  const MemberHandler({
    required MemberService service,
    required DeviceAuthenticator authenticateDevice,
  }) : _service = service,
       _authenticateDevice = authenticateDevice;

  final MemberService _service;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/members`: a fiókok az aktív eszközeikkel.
  Future<Response> list(Request request) => withDeviceCaller(
    request,
    _authenticateDevice,
    (caller) async => switch (await _service.list(caller)) {
      Ok(:final value) => privateJsonResponse(encodeMembers(value)),
      Err(:final error) => apiErrorResponse(error),
    },
  );

  /// `POST /api/auth/devices/{id}/revocation`: `204`.
  Future<Response> revokeDevice(Request request, String deviceId) => _signed(
    request,
    (caller, action) => _service.revokeDevice(caller, deviceId, action),
  );

  /// `POST /api/auth/members/{id}/removal`: `204`.
  Future<Response> removeMember(Request request, String userId) => _signed(
    request,
    (caller, action) => _service.removeMember(caller, userId, action),
  );

  Future<Response> _signed(
    Request request,
    Future<ApiError?> Function(DeviceCaller caller, SignedAction action) run,
  ) => withDeviceCaller(request, _authenticateDevice, (caller) async {
    switch (await readDecodedBody(request, decodeSignedAction)) {
      case Err(:final error):
        return apiErrorResponse(error);
      case Ok(value: final action):
        return noContentOr(await run(caller, action));
    }
  });
}
