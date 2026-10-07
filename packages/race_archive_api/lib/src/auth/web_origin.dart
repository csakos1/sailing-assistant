const Set<String> _localHosts = {'localhost', '127.0.0.1'};

/// A [value] mint a webes archívum origója, vagy `null`, ha nem az
/// (ADR 0051 D4).
///
/// Az app a regisztrációkor megjegyzi az origót, és csak erre ír alá; az
/// összevetés szöveges, ezért csak a kanonikus alakot fogadjuk el:
/// `séma://host[:port]`, kisbetűs host, alapértelmezett port nélkül, útvonal,
/// lekérdezés és felhasználó nélkül. `https` bármely hostra, `http` csak a
/// helyi fejlesztéshez (`localhost`, `127.0.0.1`).
String? canonicalWebOrigin(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  final isAllowedScheme =
      uri.scheme == 'https' ||
      (uri.scheme == 'http' && _localHosts.contains(uri.host));
  if (!isAllowedScheme) return null;
  if (uri.hasQuery || uri.hasFragment || uri.path.isNotEmpty) return null;
  return uri.origin == value ? value : null;
}
