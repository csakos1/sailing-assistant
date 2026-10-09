import 'package:shelf/shelf.dart';
import 'package:web_server/src/auth/auth_lifetimes.dart';

/// A session cookie neve (ADR 0051 D5). A `__Host-` előtag miatt a
/// böngésző csak `Secure`, `Path=/` és `Domain` nélküli cookie-t fogad el
/// ezen a néven, így egy aldomain sem írhatja felül.
const String sessionCookieName = '__Host-ft_session';

/// A belépési kérés kötő-cookie-ja (ADR 0051 D4 1. lépés).
const String loginCookieName = '__Host-ft_login';

const String _attributes = 'Path=/; Secure; HttpOnly; SameSite=Strict';

/// A [name] cookie értéke a [request]-ből, vagy `null`, ha nincs.
String? readCookie(Request request, String name) {
  final header = request.headers['cookie'];
  if (header == null) return null;
  for (final pair in header.split(';')) {
    final separator = pair.indexOf('=');
    if (separator < 0) continue;
    if (pair.substring(0, separator).trim() == name) {
      final value = pair.substring(separator + 1).trim();
      return value.isEmpty ? null : value;
    }
  }
  return null;
}

/// A session cookie a [token]-nel.
///
/// A lejárata a 90 napos felső korlát; a 7 napos tétlenséget a szerver
/// érvényesíti, így a megújításhoz nem kell új cookie.
String sessionCookie(String token) =>
    '$sessionCookieName=$token; Max-Age=${sessionMaximumLifetime.inSeconds}; '
    '$_attributes';

/// A kötő-cookie a [binding] tokennel.
String loginCookie(String binding) =>
    '$loginCookieName=$binding; '
    'Max-Age=${loginBindingCookieLifetime.inSeconds}; $_attributes';

/// A [name] cookie törlése a böngészőben.
String clearedCookie(String name) => '$name=; Max-Age=0; $_attributes';
