import 'package:flutter/material.dart';
import 'package:watch/theme/watch_colors.dart';

/// Igaz, ha a payload `twdQuality` mezője `held` — ekkor a köv-TWA hero
/// tompul és „tartott" jelet kap (ADR 0020 D7). A String a payload-kontraktus
/// (`TwdQuality.name`); ismeretlen/`null` → nem held (biztonságos default).
bool isTwdHeld(String? twdQuality) => twdQuality == 'held';

/// A `shiftConfidence` payload-String → az alsó perem-ív **színe és hossza**
/// (ADR 0023 D7), vagy `null`, ha nincs aktív predikció / ismeretlen érték.
///
/// A szint mindkét vizuális dimenziót kódolja: `high` = teal + teljes ív,
/// `medium` = borostyán + ~kétharmad, `low` = szürke + ~harmad. A `low`
/// szándékosan szürke (nem piros) — a piros a warning-csatorna (D7). A String a
/// payload-kontraktus (`WindShiftConfidence.name`); a bucket-szemantika
/// egyetlen igazságforrásból (`EstimatePredictionConfidence`) jön.
({Color color, double fraction})? confidenceArc(
  String? shiftConfidence,
  WatchColors colors,
) => switch (shiftConfidence) {
  'high' => (color: colors.signal, fraction: 1),
  'medium' => (color: colors.amber, fraction: 0.66),
  'low' => (color: colors.textTertiary, fraction: 0.33),
  _ => null,
};
