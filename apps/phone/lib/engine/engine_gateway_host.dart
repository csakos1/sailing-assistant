/// A NMEA gateway host build-időben felülírható
/// `--dart-define=FORETACK_GATEWAY_HOST=...`-fal. Ha az env var nincs
/// definiálva, a Vulcan WiFi-hotspot fix címét (`192.168.76.1`) adja vissza
/// (ADR 0007). Plain-Dart (nincs Riverpod), hogy a háttér-izolátum
/// (`RaceEngineTaskHandler`) is olvashassa; a `gatewayHostProvider` ezt
/// csomagolja a UI-rétegnek.
///
/// **Függvény, nem `const`/`final` változó** — a `String.fromEnvironment`
/// compile-time konstans, de változóként vagy a `prefer_const_declarations`
/// (`final` esetén), vagy az `avoid_redundant_argument_values` (`const`
/// esetén, a `Nmea0183TcpClient(host:)` defaultjával egyezve) lintbe ütközne.
/// Függvényhívásként egyik sem áll fenn.
String engineGatewayHost() => const String.fromEnvironment(
  'FORETACK_GATEWAY_HOST',
  defaultValue: '192.168.76.1',
);
