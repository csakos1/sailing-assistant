import 'package:flutter/material.dart';

/// A tercier szövegszín tokenje (ADR 0041 D3 + Addendum 1).
///
/// Egyetlen mezője van, mert a `text-low` az egyetlen szöveg-token, amire
/// a Material 3 `ColorScheme`-ben nem jut slot: a két outline-slotot a
/// hairline és a hairline-erős foglalja.
///
/// `ThemeExtension`, nem top-level konstans, mert a
/// `docs/design-system.md` megkötése szerint a tokeneknek témánként
/// cserélhetőnek kell lenniük. Konstansként ez lenne az egyetlen kivétel:
/// egy jövőbeli telefonos éjszakai módban a `text-hi` és a `text-mid` a
/// `ColorScheme`-mel váltana, a tercier szint viszont beragadna.
@immutable
class TextTones extends ThemeExtension<TextTones> {
  /// A tercier szövegszínt csomagolja.
  const TextTones({required this.low});

  /// Tercier szöveg: cella-feliratok és tompított kísérő szövegek.
  final Color low;

  @override
  TextTones copyWith({Color? low}) => TextTones(low: low ?? this.low);

  @override
  TextTones lerp(ThemeExtension<TextTones>? other, double t) {
    if (other is! TextTones) {
      return this;
    }
    // A Color.lerp csak akkor ad null-t, ha mindkét vég null — itt egyik
    // sem az, így a `?? low` fallback gyakorlatilag soha nem fut, csak a
    // force-unwrapot kerüli.
    return TextTones(low: Color.lerp(low, other.low, t) ?? low);
  }
}
