import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/device_token_service.dart';
import 'package:web_server/src/http/auth/device_authentication.dart';
import 'package:web_server/src/http/json_response.dart';

/// A [request] eszköz-tokenjének telefonjával futtatja a [handle]-t;
/// hiányzó, lejárt vagy visszavont eszköznél a hibaválasz (ADR 0051
/// Addendum 3 K3).
Future<Response> withDeviceCaller(
  Request request,
  DeviceAuthenticator authenticate,
  Future<Response> Function(DeviceCaller caller) handle,
) async => switch (await authenticate(request)) {
  Ok(:final value) => await handle(value),
  Err(:final error) => apiErrorResponse(error),
};

/// `204`, ha nincs [error]; különben a hibaválasz.
Response noContentOr(ApiError? error) => error == null
    ? Response(204, headers: const {'cache-control': 'no-store'})
    : apiErrorResponse(error);
