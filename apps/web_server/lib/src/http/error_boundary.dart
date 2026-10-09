import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';
import 'package:web_server/src/server_log.dart';

/// A nem várt kivételek átfordítása `InternalError`-rá (ADR 0047
/// Addendum 3 C8).
///
/// A kliens csak a kódot kapja; a kivétel és a stack trace a szerver
/// naplójába kerül, mert belső részleteket (útvonalak, SQL) nem adunk ki.
Middleware catchUnexpectedErrors(ServerLog log) =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        // A shelf ezzel jelzi a socket átvételét; nem hiba, tovább kell dobni.
        rethrow;
      } on Object catch (error, stackTrace) {
        log(
          'váratlan hiba: ${request.method} ${request.requestedUri.path}: $error\n$stackTrace',
        );
        return apiErrorResponse(const InternalError());
      }
    };
