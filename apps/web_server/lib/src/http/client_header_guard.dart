import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';

// Az olvasó metódusok mellékhatás nélküliek, ezért nem kell őket védeni.
const _safeMethods = {'GET', 'HEAD', 'OPTIONS'};

/// CSRF-védelem: módosító kérésnél kötelező az `X-Foretack-Client: web`
/// fejléc (ADR 0047 D9).
///
/// A böngésző egy idegen oldalról induló űrlap-POST-hoz nem tud egyedi
/// fejlécet tenni, egy `fetch` pedig ettől preflight-köteles lesz, amit a
/// szerver nem engedélyez. A basic auth hitelesítő adatait a böngésző
/// magától küldené, a fejlécet nem.
Middleware requireClientHeader() =>
    (inner) => (request) {
      if (_safeMethods.contains(request.method)) return inner(request);
      if (request.headers[clientHeaderName] != clientHeaderWebValue) {
        return apiErrorResponse(const MissingClientHeader());
      }
      return inner(request);
    };
