import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_body.dart';

/// A hitelesítési kérések törzsének felső korlátja: a legnagyobb (a
/// regisztráció két kulccsal és aláírással) is 1 KiB alatt van.
const int authBodyLimitBytes = 4 * 1024;

/// A [request] JSON-törzse a [decode] dekóderrel; a hibája `ApiError`.
Future<Result<T, ApiError>> readDecodedBody<T>(
  Request request,
  Result<T, DecodeError> Function(Object? json) decode,
) async {
  switch (await readJsonBody(request, limitBytes: authBodyLimitBytes)) {
    case Err(:final error):
      return Err(error);
    case Ok(value: final json):
      return switch (decode(json)) {
        Ok(:final value) => Ok(value),
        Err(:final error) => Err(MalformedRequest(error)),
      };
  }
}
