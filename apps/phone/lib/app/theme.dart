import 'package:flutter/material.dart';
import 'package:phone/app/confidence_colors.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/warning_colors.dart';

/// A Foretack app Material 3 témája — marine dark (§8.7).
///
/// Sötét, magas kontrasztú felület a napfény-olvashatóságért; a
/// confidence-színeket a [ConfidenceColors] `ThemeExtension` hordozza, a
/// cellák onnan olvassák. App-wide dark — a CRUD-screenek is öröklik.
///
/// Az UI-szövegek betűcsaládja app-szinten az IBM Plex Sans (ADR 0041
/// D5); a mérőszámok stílusai nem itt élnek, hanem a
/// `foretack_typography.dart` konstansaiban.
final ThemeData foretackTheme = _buildForetackTheme();

ThemeData _buildForetackTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E9FB5),
    brightness: Brightness.dark,
  ).copyWith(surface: const Color(0xFF0B0F14));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: uiFontFamily,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [
      ConfidenceColors(
        low: Color(0xFF6B7785),
        medium: Color(0xFFE0A82E),
        high: Color(0xFF35C2D6),
      ),
      WarningColors(
        critical: Color(0xFFB3261E),
        warning: Color(0xFFE0A82E),
        info: Color(0xFF24323F),
      ),
    ],
  );
}
