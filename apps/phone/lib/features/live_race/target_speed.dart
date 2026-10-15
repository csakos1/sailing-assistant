// A target-% maga az engine-ben számolódik
// (`RaceSnapshot.targetSpeedPercent`, ADR 0058 D10), hogy a kijelzők és az
// óra ugyanazt az értéket mutassák; itt csak a megjelenítése él.

/// A cél-sebesség százalék megjelenítése: `null` → „—", egyébként egész %.
String formatTargetSpeedPercent(double? percent) {
  if (percent == null) {
    return '—';
  }
  return '${percent.round()}%';
}
