import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/account_security_service.dart';
import 'package:web_server/src/http/auth/decoded_json_body.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/auth/device_caller_response.dart';
import 'package:web_server/src/http/auth/private_json_response.dart';
import 'package:web_server/src/http/json_response.dart';

/// A tartalék belépés beállításainak végpontjai a telefonon (ADR 0051
/// Addendum 6 N4): állapot, jelszó, kódok.
class AccountSecurityHandler {
  /// Handler a [service] fölött.
  const AccountSecurityHandler({
    required AccountSecurityService service,
    required DeviceAuthenticator authenticateDevice,
  }) : _service = service,
       _authenticateDevice = authenticateDevice;

  final AccountSecurityService _service;
  final DeviceAuthenticator _authenticateDevice;

  /// `GET /api/auth/account/security`: a jelszó és a kódok állapota.
  Future<Response> security(Request request) => withDeviceCaller(
    request,
    _authenticateDevice,
    (caller) async => switch (await _service.security(caller)) {
      Ok(:final value) => privateJsonResponse(encodeAccountSecurity(value)),
      Err(:final error) => apiErrorResponse(error),
    },
  );

  /// `POST /api/auth/account/password`: `204`.
  Future<Response> setPassword(Request request) =>
      withDeviceCaller(request, _authenticateDevice, (caller) async {
        switch (await readDecodedBody(request, decodePasswordChange)) {
          case Err(:final error):
            return apiErrorResponse(error);
          case Ok(value: final change):
            return noContentOr(await _service.setPassword(caller, change));
        }
      });

  /// `POST /api/auth/account/recovery-codes`: `201`, a 10 új kód.
  Future<Response> regenerateRecoveryCodes(Request request) =>
      withDeviceCaller(request, _authenticateDevice, (caller) async {
        switch (await readDecodedBody(request, decodeSignedAction)) {
          case Err(:final error):
            return apiErrorResponse(error);
          case Ok(value: final action):
            final result = await _service.regenerateRecoveryCodes(
              caller,
              action,
            );
            return switch (result) {
              Ok(:final value) => privateJsonResponse(
                encodeIssuedRecoveryCodes(value),
                statusCode: 201,
              ),
              Err(:final error) => apiErrorResponse(error),
            };
        }
      });
}
