/// Hogyan lépett be egy webes munkamenet (ADR 0051 D7).
///
/// A `name` a dróton és az `auth.sqlite`-ban is ugyanez a szöveg; az app a
/// munkamenet-sorban `QR`, `JELSZÓ`, `KÓD` címkét mutat (Addendum 1 H9).
enum LoginMethod {
  /// QR-kód és ujjlenyomat a telefonon.
  qr,

  /// Tartalék-jelszó (csak az `owner`).
  password,

  /// Helyreállító kód (csak az `owner`).
  recoveryCode,
}
