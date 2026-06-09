/// A derivált True Wind Direction (TWD) minősége (ADR 0020).
///
/// A `WindObservation.twdQuality` és a `TwdEstimate` hordozza; a
/// `DeriveTrueWindDirection` use case állítja elő.
enum TwdQuality {
  /// Friss, COG-alapú becslés — a SOG az érdemi-mozgás küszöb fölött van.
  live,

  /// SOG-küszöb alatt vagy hiányzó input → az utolsó jó TWD tartva.
  held,

  /// Még nem volt jó becslés — nincs derivált TWD.
  unavailable,
}
