import 'package:flutter/material.dart';
import 'package:watch/theme/watch_colors.dart';

/// Az óra app-szintű sötét témája (`docs/design-system.md`, ADR 0015 D7).
///
/// A szín-tokeneket a [WatchColors] `ThemeExtension` hordozza; a widgetek
/// onnan olvasnak. v1 sötét-only.
final ThemeData watchDarkTheme = _buildWatchDarkTheme();

ThemeData _buildWatchDarkTheme() {
  const colors = WatchColors(
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
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.signal,
    brightness: Brightness.dark,
  ).copyWith(surface: colors.surface);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    extensions: const [colors],
  );
}
