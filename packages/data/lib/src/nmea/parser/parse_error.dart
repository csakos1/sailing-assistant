/// Miért nem alakítható egy NMEA 0183 sor `Sentence`-szé.
///
/// Enum, nem sealed class: a `ConnectionError`-ral ellentétben (5.3) nincs
/// üzenet-fogyasztója — a hibás sort csak eldobjuk (ARCHITECTURE.md 6.3).
enum ParseError {
  /// Üres vagy csak whitespace sor (a `LineSplitter` is adhat ilyet).
  empty,

  /// Szerkezeti hiba: nincs `$`/`!` kezdet, hiányzó/rossz `*` blokk, vagy
  /// túl rövid address-token.
  malformed,

  /// A `*` utáni XOR checksum nem egyezik a payloadból számolttal.
  checksumMismatch,
}
