// A hitelesítés időzítései egy helyen (ADR 0051 D3, D4, D5, Addendum 1
// H2, Addendum 3 K2, K3, K5, Addendum 5 M2–M5).

/// A belépési kérés élete a nyitástól, illetve egy telefon megnyitása
/// vagy jóváhagyása után.
const Duration loginRequestStepLifetime = Duration(seconds: 60);

/// A kötő-cookie élete; a `joinPending` kérés 10 percéhez igazodik (A2b).
const Duration loginBindingCookieLifetime = Duration(minutes: 10);

/// Az eszköz-token kihívásának élete.
const Duration deviceChallengeLifetime = Duration(seconds: 60);

/// Az eszköz-token élete.
const Duration deviceTokenLifetime = Duration(minutes: 15);

/// A session lejár ennyi tétlenség után.
const Duration sessionIdleTimeout = Duration(days: 7);

/// A session abszolút felső korlátja a belépéstől.
const Duration sessionMaximumLifetime = Duration(days: 90);

/// A session aktivitása legfeljebb ilyen gyakran íródik a DB-be.
const Duration sessionTouchInterval = Duration(hours: 1);

/// Egy csatlakozási kérelem élete (ADR 0051 D3), döntés után is: a
/// telefon a jóváhagyást eddig kérdezheti le (Addendum 5 M4).
const Duration joinRequestLifetime = Duration(hours: 24);

/// A böngésző ennyit vár egy csatlakozási kérelemre (`joinPending`, D3).
const Duration joinPendingLoginLifetime = Duration(minutes: 10);

/// Az ujjlenyomatos művelet kihívásának élete (Addendum 5 M2).
const Duration actionChallengeLifetime = Duration(seconds: 60);
