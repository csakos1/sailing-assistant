import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// A wind-shift confidence-szintek megjelenítési színei (§8.7).
///
/// `ThemeExtension`, hogy a téma adja és a cellák
/// `Theme.of(context).extension<ConfidenceColors>()`-szal olvassák. A
/// [high] szándékosan accent (nem zöld) — a zöld/piros a starboard/port
/// oldal-nyilaké marad, hogy a két szín-szemantika ne ütközzön.
@immutable
class ConfidenceColors extends ThemeExtension<ConfidenceColors> {
  /// A három confidence-szint színét csomagolja.
  const ConfidenceColors({
    required this.low,
    required this.medium,
    required this.high,
  });

  /// Alacsony megbízhatóság (tompított — megbízhatatlan, nem riasztás).
  final Color low;

  /// Közepes megbízhatóság (borostyán).
  final Color medium;

  /// Magas megbízhatóság (accent; nem zöld).
  final Color high;

  /// A [confidence]-szinthez tartozó szín.
  Color forConfidence(WindShiftConfidence confidence) => switch (confidence) {
    WindShiftConfidence.low => low,
    WindShiftConfidence.medium => medium,
    WindShiftConfidence.high => high,
  };

  @override
  ConfidenceColors copyWith({Color? low, Color? medium, Color? high}) =>
      ConfidenceColors(
        low: low ?? this.low,
        medium: medium ?? this.medium,
        high: high ?? this.high,
      );

  @override
  ConfidenceColors lerp(ThemeExtension<ConfidenceColors>? other, double t) {
    if (other is! ConfidenceColors) {
      return this;
    }
    // A Color.lerp csak akkor ad null-t, ha mindkét vég null — itt egyik
    // sem az, így a `?? this.x` fallback gyakorlatilag soha nem fut, csak
    // a force-unwrapot kerüli.
    return ConfidenceColors(
      low: Color.lerp(low, other.low, t) ?? low,
      medium: Color.lerp(medium, other.medium, t) ?? medium,
      high: Color.lerp(high, other.high, t) ?? high,
    );
  }
}
