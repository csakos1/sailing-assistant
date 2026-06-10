import 'package:flutter/material.dart';

/// Az óra sötét témájának szín-tokenjei (`docs/design-system.md`).
///
/// `ThemeExtension` a phone `ConfidenceColors`/`WarningColors` mintájára: a
/// téma adja, a widgetek `Theme.of(context).extension<WatchColors>()`-szal
/// olvassák. v1-ben csak a sötét téma (ADR 0015 D7); a Napfény/Piros téma
/// v2-deferred, így később drop-in egy másik `WatchColors`-példánnyal.
@immutable
class WatchColors extends ThemeExtension<WatchColors> {
  /// Csomagolja az óra megjelenítési szín-tokenjeit.
  const WatchColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.signal,
    required this.critical,
    required this.port,
    required this.starboard,
    this.amber = const Color(0xFFFFB300),
  });

  /// Háttér (OLED-fekete).
  final Color background;

  /// Kártya / emelt felület.
  final Color surface;

  /// Elsődleges szöveg / hero-érték.
  final Color text;

  /// Másodlagos szöveg / label.
  final Color textSecondary;

  /// Tercier / tompított (pl. nem megbízható GPS-idő pötty; low konfidencia-ív).
  final Color textTertiary;

  /// Live / optimális (teal) — friss GPS, predikció; high konfidencia-ív.
  final Color signal;

  /// Kritikus (warning keret / ikon).
  final Color critical;

  /// Bal (port, piros) — hajós konvenció.
  final Color port;

  /// Jobb (starboard, zöld) — hajós konvenció.
  final Color starboard;

  /// Borostyán — a medium predikció-konfidencia (alsó ív) színe (ADR 0023 D7).
  /// Additív token; a default a kanonikus téma-érték, így a meglévő
  /// [WatchColors]-konstrukciók (téma + tesztek) változatlanul fordulnak.
  final Color amber;

  @override
  WatchColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? signal,
    Color? critical,
    Color? port,
    Color? starboard,
    Color? amber,
  }) => WatchColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    signal: signal ?? this.signal,
    critical: critical ?? this.critical,
    port: port ?? this.port,
    starboard: starboard ?? this.starboard,
    amber: amber ?? this.amber,
  );

  @override
  WatchColors lerp(ThemeExtension<WatchColors>? other, double t) {
    if (other is! WatchColors) {
      return this;
    }
    return WatchColors(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      text: Color.lerp(text, other.text, t) ?? text,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      signal: Color.lerp(signal, other.signal, t) ?? signal,
      critical: Color.lerp(critical, other.critical, t) ?? critical,
      port: Color.lerp(port, other.port, t) ?? port,
      starboard: Color.lerp(starboard, other.starboard, t) ?? starboard,
      amber: Color.lerp(amber, other.amber, t) ?? amber,
    );
  }
}
