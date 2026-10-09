/// Egy webes fiók szerepe (ADR 0051 D2).
///
/// A `name` a dróton és az `auth.sqlite`-ban is ugyanez a szöveg.
enum UserRole {
  /// A tulajdonos: egy van, mindent lát és szerkeszt, ő hagyja jóvá a
  /// legénységet.
  owner,

  /// A legénység: a Lola archívumát csak nézi, export nélkül.
  crew,
}
