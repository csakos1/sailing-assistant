import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/session_directory.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';

/// A „Webes belépések" végpontjai (ADR 0051 D7, Addendum 5 M8): lista és
/// kiléptetés, eszköz-tokennel.
class SessionListHandler {
  /// Handler a [directory] fölött.
  const SessionListHandler({
    required SessionDirectory directory,
    required DeviceAuthenticator authenticateDevice,
  }) : _directory = directory,
       _authenticateDevice = authenticateDevice;

  final SessionDirectory _directory;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/sessions`: a látható élő munkamenetek.
  Future<Response> list(Request request) => withDeviceCaller(
    request,
    _authenticateDevice,
    (caller) async =>
        privateJsonResponse(encodeWebSessions(await _directory.list(caller))),
  );

  /// `DELETE /api/auth/sessions/{id}`: `204`.
  Future<Response> terminate(Request request, String sessionId) =>
      withDeviceCaller(
        request,
        _authenticateDevice,
        (caller) async =>
            noContentOr(await _directory.terminate(caller, sessionId)),
      );
}
