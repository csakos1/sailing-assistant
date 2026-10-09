/// A böngésző és az OS neve egy User-Agentből; bármelyik lehet ismeretlen.
typedef UserAgentDescription = ({String? browser, String? os});

// A sorrend számít: az Edge és az Opera User-Agentje a „Chrome/”-ot, a
// Chrome-é a „Safari/”-t is tartalmazza, ezért a szűkebb jel áll elöl.
const List<(String, List<String>)> _browsers = [
  ('Edge', ['Edg/', 'EdgA/', 'EdgiOS/']),
  ('Opera', ['OPR/', 'OPiOS/']),
  ('Firefox', ['Firefox/', 'FxiOS/']),
  ('Chrome', ['Chrome/', 'CriOS/']),
  ('Safari', ['Safari/']),
];

// Az Android és a ChromeOS User-Agentje a „Linux”-ot, az iPadé gyakran a
// „Mac OS X”-et is tartalmazza, ezért ezek állnak elöl.
const List<(String, List<String>)> _systems = [
  ('Windows', ['Windows NT']),
  ('ChromeOS', ['CrOS']),
  ('Android', ['Android']),
  ('iOS', ['iPhone', 'iPad', 'iPod']),
  ('macOS', ['Macintosh', 'Mac OS X']),
  ('Linux', ['Linux']),
];

/// A [userAgent] böngészője és OS-e, ahogy a telefon az
/// ujjlenyomat-ablakban és a „Webes belépések" képernyőn mutatja (ADR
/// 0051 D7, Addendum 3 K11).
///
/// Szándékosan kicsi: csak a gyakori böngészőket és rendszereket ismeri,
/// verziót nem ad (a Windows-verzió a User-Agentből amúgy sem olvasható
/// ki). Amit nem ismer, az `null`.
UserAgentDescription describeUserAgent(String? userAgent) {
  if (userAgent == null) return (browser: null, os: null);
  return (
    browser: _firstMatch(_browsers, userAgent),
    os: _firstMatch(_systems, userAgent),
  );
}

String? _firstMatch(List<(String, List<String>)> rules, String userAgent) {
  for (final (name, markers) in rules) {
    if (markers.any(userAgent.contains)) return name;
  }
  return null;
}
