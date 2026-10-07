import 'package:shelf/shelf.dart';

final RegExp _bearer = RegExp(r'^Bearer ([A-Za-z0-9_-]+)$');

/// Az `Authorization: Bearer <token>` fejléc tokenje, vagy `null`, ha
/// nincs, vagy nem ilyen alakú (ADR 0051 Addendum 3 K3).
String? bearerTokenOf(Request request) {
  final header = request.headers['authorization'];
  if (header == null) return null;
  return _bearer.firstMatch(header)?.group(1);
}

/// Hoz-e a [request] `Authorization` fejlécet; ilyenkor az eszköz-token
/// dönt, nem a session cookie.
bool hasAuthorizationHeader(Request request) =>
    request.headers.containsKey('authorization');
