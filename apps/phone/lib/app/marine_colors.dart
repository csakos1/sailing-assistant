import 'package:flutter/material.dart';

/// Starboard (jobb) oldal — hajós (navigációs-fény) konvenció szerint zöld.
const Color starboardColor = Color(0xFF34C759);

/// Port (bal) oldal — hajós (navigációs-fény) konvenció szerint piros.
const Color portColor = Color(0xFFE5484D);

/// A track gradient-színezés rámpája (ADR 0034 Addendum 4): lassú zöld →
/// sárga → gyors piros, fix 0–8 csomóra normalizálva, 8 sávban. A szín
/// abszolút sebességet jelent, így két verseny track-je összevethető.
const List<Color> _trackSpeedBands = [
  Color(0xFF2FB344), // 0: 0–1 kn (zöld)
  Color(0xFF68B946), // 1: 1–2 kn
  Color(0xFFA0BF47), // 2: 2–3 kn
  Color(0xFFD9C549), // 3: 3–4 kn
  Color(0xFFF3B64A), // 4: 4–5 kn
  Color(0xFFEE914B), // 5: 5–6 kn
  Color(0xFFEA6D4C), // 6: 6–7 kn
  Color(0xFFE5484D), // 7: 7–8+ kn (piros)
];

/// A hiányzó sebességű (SOG nélküli) track-szakasz semleges szürkéje.
const Color trackSpeedUnknownColor = Color(0xFF9E9E9E);

/// A [sogMps] (m/s) sebességhez tartozó sáv-szín a zöld→piros rámpán (fix
/// 0–8 csomó, 8 sáv, 1 csomós lépcsőkkel). `null` esetén
/// [trackSpeedUnknownColor].
Color colorForTrackSpeed(double? sogMps) {
  if (sogMps == null) return trackSpeedUnknownColor;
  // m/s -> csomó, majd a 0..7 sávindexre vágva (8+ kn is a 7. sáv).
  final band = (sogMps * 1.943844).floor().clamp(0, 7);
  return _trackSpeedBands[band];
}
