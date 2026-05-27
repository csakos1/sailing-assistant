import 'package:flutter/material.dart';

/// A Foretack app aktuális Material 3 témája.
///
/// A v1 fázisokban (3 és 4) a debug-viewer és a konfigurációs képernyők
/// használják; a Fázis 5 főképernyő majd kidolgozza a marine-stílust
/// (sötét háttér, high-contrast számok). Most a Material 3 dark
/// alapértékek elegek — nem akarunk YAGNI-szembe tervezni.
final ThemeData foretackTheme = ThemeData.dark(useMaterial3: true);
