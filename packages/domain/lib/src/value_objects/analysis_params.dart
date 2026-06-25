/// Az elemzes hangolhato parameterei (ADR 0025 D4, ADR 0026). Mindegyik
/// CLI-flag.
class AnalysisParams {
  /// Alapertelmezett hangolas.
  const AnalysisParams({
    this.settleSkip = const Duration(seconds: 10),
    this.settleWindow = const Duration(seconds: 20),
    this.cogToleranceDeg = 20,
    this.settleConfirm = const Duration(seconds: 3),
    this.leadTrustLevels = const {'high'},
  });

  /// A korozes utan ennyit MINDENKEPP kihagyunk, mire a COG-kapu nyilhat
  /// (floor; ADR 0026 D5).
  final Duration settleSkip;

  /// A kapu nyitasatol ezen az ablakon atlagoljuk a tenyleges TWA-t.
  final Duration settleWindow;

  /// A COG es a leg-irany megengedett elterese fokban; ezen belul a hajo
  /// "rajta van az uj legen" (ADR 0026 D3). 360 = a regi fix-ido mod (D6).
  final double cogToleranceDeg;

  /// A kapu ennyi ideig tarto folyamatos in-tolerance allapotra var a
  /// nyitashoz (debounce; ADR 0026 D4).
  final Duration settleConfirm;

  /// Mely `shiftConfidence`-szintek szamitanak "megbizhatonak" a lead-time-hoz.
  final Set<String> leadTrustLevels;
}
