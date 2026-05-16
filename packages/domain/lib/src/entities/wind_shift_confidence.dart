/// A wind-shift trend megbízhatósága a sliding-window lineáris
/// regresszió r² értéke alapján.
///
/// A `CalculateWindShiftTrend` use case (ARCHITECTURE.md 7.4) az
/// alábbi r² küszöbökkel sorol be: `> 0.7` → [high], `> 0.4` →
/// [medium], egyébként → [low]. A [low] érték a default akkor is, ha
/// nincs elég adat trend-számoláshoz (insufficient sample).
enum WindShiftConfidence {
  low,
  medium,
  high,
}
