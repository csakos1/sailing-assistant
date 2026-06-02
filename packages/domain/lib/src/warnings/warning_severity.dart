/// Egy `Warning` súlyossága a megjelenítéshez (ARCHITECTURE.md 11.,
/// ADR 0014).
///
/// A felsorolás sorrendje a súlyosság növekvő rendje; a UI ez alapján
/// rangsorol és választ render-stílust: info → diszkrét jelzés,
/// warning → borostyán csík, critical → piros banner + grid-tompítás
/// (ADR 0014 D6).
enum WarningSeverity {
  /// Tájékoztató jelzés; a verseny-adat továbbra is használható.
  info,

  /// Figyelmeztetés; az adat egy része megbízhatatlan lehet.
  warning,

  /// Kritikus; az alapadat (kapcsolat vagy GPS) hiányzik, a grid nem
  /// megbízható.
  critical,
}
