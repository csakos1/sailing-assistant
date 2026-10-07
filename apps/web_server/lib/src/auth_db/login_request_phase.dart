/// Egy belépési kérés belső állapota a szerveren (ADR 0051 Addendum 3
/// K5).
///
/// A `name` kerül a `login_requests.state` oszlopba. A web ennél kevesebbet
/// lát (`LoginRequestState`): a jóváhagyást nem látja külön, mert a
/// következő lekérdezése már beváltja (`signedIn`).
enum LoginRequestPhase {
  /// Még senki nem nyitotta meg.
  pending,

  /// Egy telefon megnyitotta, ujjlenyomatra vár.
  opened,

  /// Egy telefon jóváhagyta; a kötő-cookie-s böngésző beválthatja.
  approved,
}
