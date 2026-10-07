import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/join_decision_service.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// Az `owner` végpontjai a csatlakozási kérelmekhez (ADR 0051 Addendum 5
/// M6): lista, jóváhagyás, elutasítás, mind eszköz-tokennel.
class JoinDecisionHandler {
  /// Handler a [service] fölött.
  const JoinDecisionHandler({
    required JoinDecisionService service,
    required DeviceAuthenticator authenticateDevice,
  }) : _service = service,
       _authenticateDevice = authenticateDevice;

  final JoinDecisionService _service;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/join-requests`: az el nem döntött kérelmek.
  Future<Response> list(Request request) => withDeviceCaller(
    request,
    _authenticateDevice,
    (caller) async => switch (await _service.listPending(caller)) {
      Ok(:final value) => privateJsonResponse(
        encodePendingJoinRequests(value),
      ),
      Err(:final error) => apiErrorResponse(error),
    },
  );

  /// `POST …/{id}/approval`: a tag az aktív eszközeivel.
  Future<Response> approve(Request request, String joinRequestId) =>
      withDeviceCaller(request, _authenticateDevice, (caller) async {
        switch (await readDecodedBody(request, decodeJoinApproval)) {
          case Err(:final error):
            return apiErrorResponse(error);
          case Ok(value: final approval):
            final result = await _service.approve(
              caller,
              joinRequestId,
              approval,
            );
            return switch (result) {
              Ok(:final value) => privateJsonResponse(encodeMemberInfo(value)),
              Err(:final error) => apiErrorResponse(error),
            };
        }
      });

  /// `POST …/{id}/rejection`: `204`.
  Future<Response> reject(Request request, String joinRequestId) =>
      withDeviceCaller(
        request,
        _authenticateDevice,
        (caller) async =>
            noContentOr(await _service.reject(caller, joinRequestId)),
      );
}
