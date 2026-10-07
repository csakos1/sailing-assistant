import 'package:http/http.dart' as http;
import 'package:race_archive_api/race_archive_api.dart';

/// Egy HTTP-kliens burka, amely a lejárt munkamenetet jelzi (ADR 0051
/// Addendum 7 P3).
///
/// Ha egy válasz `401`, és a kérés nem a `/api/auth/` alá ment, az
/// `onUnauthorized` fut: a munkamenet lejárt, a web a belépő képernyőre
/// vált. Az `/api/auth/*` hívások a saját `401`-jüket maguk kezelik (pl.
/// a tartalék belépés hibája), ezért ezekhez nem nyúl. A választ
/// változatlanul továbbadja: a hívó a saját hibájaként is látja.
///
/// A `close` nem zárja a belső klienst: annak a gazdája a
/// `httpClientProvider`.
class SessionAwareClient extends http.BaseClient {
  /// Burok a [_inner] kliens körül.
  SessionAwareClient(this._inner, {required void Function() onUnauthorized})
    : _onUnauthorized = onUnauthorized;

  final http.Client _inner;
  final void Function() _onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401 &&
        !request.url.path.startsWith(authPathPrefix)) {
      _onUnauthorized();
    }
    return response;
  }
}
