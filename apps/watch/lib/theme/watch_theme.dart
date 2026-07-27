import 'package:flutter/material.dart';
import 'package:watch/theme/watch_colors.dart';

/// Az óra nappali szín-tokenjei (`docs/design-system.md`, ADR 0015 D7).
const WatchColors watchDayColors = WatchColors(
  background: Color(0xFF04080D),
  surface: Color(0xFF0D1822),
  text: Color(0xFFE9F1F7),
  textSecondary: Color(0xFF93A8BA),
  textTertiary: Color(0xFF5C7285),
  signal: Color(0xFF16E0C4),
  critical: Color(0xFFFF4D4D),
  port: Color(0xFFFF5A52),
  starboard: Color(0xFF2FD06E),
);

/// Az óra éjszakai szín-tokenjei (ADR 0039 D2–D4).
///
/// Szándékosan a nappali készletből származik: **csak a három szöveg-token
/// és a `onCritical` vált**, minden jelentés-hordozó szín (port/starboard,
/// critical, signal, amber) és a felületek változatlanok. Így a „csak a
/// szöveg-rámpa vált” invariánst a szerkezet tartja, nem egy teszt.
final WatchColors watchNightColors = watchDayColors.copyWith(
  text: const Color(0xFFEE5035),
  textSecondary: const Color(0xFFA63825),
  textTertiary: const Color(0xFF8C2F1F),
  onCritical: watchDayColors.background,
);

/// Az óra app-szintű sötét (nappali) témája.
///
/// A szín-tokeneket a [WatchColors] `ThemeExtension` hordozza; a widgetek
/// onnan olvasnak.
final ThemeData watchDarkTheme = _buildTheme(
  watchDayColors,
  _baseScheme(watchDayColors),
);

/// Az óra éjszakai témája: napnyugta után ez van érvényben (ADR 0039).
///
/// A `ColorScheme` `onSurface`/`onSurfaceVariant` mezőjét is a narancs
/// rámpára állítja, hogy az explicit szín nélküli `Text`-ek se maradjanak
/// fehérek (ADR 0039 D5). A nappali téma sémája ezért változatlan.
final ThemeData watchNightTheme = _buildTheme(
  watchNightColors,
  _baseScheme(watchNightColors).copyWith(
    onSurface: watchNightColors.text,
    onSurfaceVariant: watchNightColors.textSecondary,
  ),
);

ColorScheme _baseScheme(WatchColors colors) => ColorScheme.fromSeed(
  seedColor: colors.signal,
  brightness: Brightness.dark,
).copyWith(surface: colors.surface);

ThemeData _buildTheme(WatchColors colors, ColorScheme scheme) => ThemeData(
  useMaterial3: true,
  colorScheme: scheme,
  scaffoldBackgroundColor: colors.background,
  extensions: [colors],
);
