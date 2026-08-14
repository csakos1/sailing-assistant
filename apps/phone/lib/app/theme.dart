import 'package:flutter/material.dart';
import 'package:phone/app/confidence_colors.dart';
import 'package:phone/app/foretack_typography.dart';
import 'package:phone/app/text_tones.dart';
import 'package:phone/app/warning_colors.dart';

/// A Foretack app Material 3 témája — marine dark (§8.7).
///
/// Sötét, magas kontrasztú felület a napfény-olvashatóságért; a
/// confidence-színeket a [ConfidenceColors] `ThemeExtension` hordozza, a
/// cellák onnan olvassák. App-wide dark — a CRUD-screenek is öröklik.
///
/// Az űrlap-mezők alapértelmezését az `inputDecorationTheme` hordozza
/// (ADR 0044 D3): kitöltött mező, 12 dp-s kontúr, `outline` kerettel és
/// kétsoros hibaszöveggel. A bója-kártyán belüli mezők ezt lokálisan
/// szűkítik, mert ott a kártya háttere már `surfaceContainer`.
///
/// Az UI-szövegek betűcsaládja app-szinten az IBM Plex Sans (ADR 0041
/// D5); a mérőszámok stílusai nem itt élnek, hanem a
/// `foretack_typography.dart` konstansaiban.
final ThemeData foretackTheme = _buildForetackTheme();

ThemeData _buildForetackTheme() {
  // A fromSeed a magot tonálisan átképzi, ezért minden token-slotot
  // explicit rögzítünk (ADR 0041 D1) — még a `primary` sem lenne
  // pontosan a mag színe. Az `onError` egy slottal több az ADR
  // táblázatánál: generálva sötét lenne a kézzel állított `error`-on.
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E9FB5),
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF0B0F14),
        surfaceContainer: const Color(0xFF111823),
        surfaceContainerHigh: const Color(0xFF182230),
        outlineVariant: const Color(0xFF1E2A38),
        outline: const Color(0xFF2A3B4E),
        onSurface: const Color(0xFFF2F7FA),
        onSurfaceVariant: const Color(0xFF9FB2C2),
        primary: const Color(0xFF1E9FB5),
        onPrimary: const Color(0xFF04262B),
        secondaryContainer: const Color(0xFF16323A),
        onSecondaryContainer: const Color(0xFF9FD9E4),
        error: const Color(0xFFB3261E),
        onError: const Color(0xFFFFFFFF),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: uiFontFamily,
    scaffoldBackgroundColor: scheme.surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      border: foretackFieldBorder(scheme.outline),
      enabledBorder: foretackFieldBorder(scheme.outline),
      focusedBorder: foretackFieldBorder(scheme.primary, width: 1.5),
      errorBorder: foretackFieldBorder(scheme.error, width: 1.5),
      focusedErrorBorder: foretackFieldBorder(
        scheme.error,
        width: 1.5,
      ),
      errorMaxLines: 2,
    ),
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
      TextTones(low: Color(0xFF66788A)),
    ],
  );
}

/// Egy mező-kontúr a témához (ADR 0044 D3).
///
/// A radius minden állapotban azonos, csak a vonal színe és vastagsága
/// vált — így a fókusz és a hiba nem mozdítja el a mező geometriáját.
/// A [radius] alapértéke **0**: a szögletesség nem képernyő-lokális
/// stílus, hanem a 2a/3a/5d közös nyelve, ezért a token-rétegben dől
/// el (ADR 0044 D47). Publikus, mert a kártya-dekoráció a
/// `race_form.dart`-ban épül, és a létra másolása két helyre
/// szétcsúszást hívna elő.
OutlineInputBorder foretackFieldBorder(
  Color color, {
  double width = 1,
  double radius = 0,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    borderSide: BorderSide(color: color, width: width),
  );
}
