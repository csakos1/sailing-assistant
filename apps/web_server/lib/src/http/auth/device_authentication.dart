import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/http/auth/bearer_token.dart';

/// Egy kérés eszköz-tokenjének telefonja, vagy a hiba.
typedef DeviceAuthenticator =
    Future<Result<DeviceCaller, ApiError>> Function(Request request);

/// Eszköz-hitelesítés a [tokens] fölött (ADR 0051 Addendum 3 K3).
///
/// Hiányzó vagy hibás alakú `Authorization` fejléc: `NotAuthenticated`.
DeviceAuthenticator deviceAuthenticatorOver(DeviceTokenService tokens) =>
    (request) async {
      final token = bearerTokenOf(request);
      if (token == null) return const Err(NotAuthenticated());
      return tokens.callerOf(token);
    };
