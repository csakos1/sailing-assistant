import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/account_name_service.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// `POST /api/auth/account/name`: a saját név átírása (ADR 0051
/// Addendum 5 M9); `200`, az új fiók.
class AccountNameHandler {
  /// Handler a [service] fölött.
  const AccountNameHandler({
    required AccountNameService service,
    required DeviceAuthenticator authenticateDevice,
  }) : _service = service,
       _authenticateDevice = authenticateDevice;

  final AccountNameService _service;
  final DeviceAuthenticator _authenticateDevice;

  /// Az átnevezés.
  Future<Response> call(Request request) =>
      withDeviceCaller(request, _authenticateDevice, (caller) async {
        switch (await readDecodedBody(request, decodeDisplayNameChange)) {
          case Err(:final error):
            return apiErrorResponse(error);
          case Ok(value: final name):
            return switch (await _service.rename(caller, name)) {
              Ok(:final value) => privateJsonResponse(encodeAccountInfo(value)),
              Err(:final error) => apiErrorResponse(error),
            };
        }
      });
}
