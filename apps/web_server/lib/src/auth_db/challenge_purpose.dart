/// Mire szól egy szerveroldali kihívás (ADR 0051 Addendum 5 M2).
///
/// A `name` kerül a `challenges.purpose` oszlopba. A kettő nem cserélhető:
/// egy eszköz-tokenhez kért kihívással nem írható alá művelet, és fordítva.
enum ChallengePurpose {
  /// Eszköz-token kérése a csendes eszközkulccsal (Addendum 3 K3).
  deviceToken,

  /// Ujjlenyomatos művelet az aláíró kulccsal (Addendum 3 K4).
  action,
}
