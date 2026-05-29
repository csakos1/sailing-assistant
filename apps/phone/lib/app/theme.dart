import 'package:flutter/material.dart';
import 'package:phone/app/confidence_colors.dart';

/// A Foretack app Material 3 témája — marine dark (§8.7).
///
/// Sötét, magas kontrasztú felület a napfény-olvashatóságért; a
/// confidence-színeket a [ConfidenceColors] `ThemeExtension` hordozza, a
/// cellák onnan olvassák. App-wide dark — a CRUD-screenek is öröklik.
final ThemeData foretackTheme = _buildForetackTheme();

ThemeData _buildForetackTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E9FB5),
    brightness: Brightness.dark,
  ).copyWith(surface: const Color(0xFF0B0F14));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [
      ConfidenceColors(
        low: Color(0xFF6B7785),
        medium: Color(0xFFE0A82E),
        high: Color(0xFF35C2D6),
      ),
    ],
  );
}
