import 'package:race_archive_api/race_archive_api.dart';
import 'package:shelf/shelf.dart';
import 'package:web_server/src/http/json_response.dart';

// Az olvasó metódusok mellékhatás nélküliek, ezért nem kell őket védeni.
const _safeMethods = {'GET', 'HEAD', 'OPTIONS'};

// A web és a telefon értéke (ADR 0051 D9). A védelem a fejléc puszta
// jelenlétéből jön, ezért mindkettő mindenhol elfogadott.
const Set<String> _clientValues = {
  clientHeaderWebValue,
  clientHeaderPhoneValue,
};

/// CSRF-védelem: módosító kérésnél kötelező az `X-Foretack-Client`
/// fejléc `web` vagy `phone` értékkel (ADR 0047 D9, ADR 0051 Addendum 4
/// L4).
///
/// A böngésző egy idegen oldalról induló űrlap-POST-hoz nem tud egyedi
/// fejlécet tenni, egy `fetch` pedig ettől preflight-köteles lesz, amit a
/// szerver nem engedélyez. A cookie-t a böngésző magától küldené, a
/// fejlécet nem.
Middleware requireClientHeader() =>
    (inner) => (request) {
      if (_safeMethods.contains(request.method)) return inner(request);
      if (!_clientValues.contains(request.headers[clientHeaderName])) {
        return apiErrorResponse(const MissingClientHeader());
      }
      return inner(request);
    };
