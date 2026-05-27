import 'package:flutter/material.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/debug/raw_nmea_viewer_screen.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A Foretack app gyökér-widgetje.
///
/// A Riverpod `ProviderScope` kívülről jön (a `main`-ből), itt csak a
/// `MaterialApp`, a téma és a lokalizációs delegátorok élnek. A v1
/// főképernyő (Fázis 5) majd a `home:` slot cseréjével landol; jelenleg
/// a debug raw-NMEA viewer az egyetlen képernyő (§14 Fázis 3).
///
/// Az `AppLocalizations.of(context)!` használat a fában a `MaterialApp`
/// alatt biztonságos: a delegátorokat itt regisztráljuk, így a fa minden
/// gyermekében garantáltan elérhető.
class ForetackApp extends StatelessWidget {
  const ForetackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: foretackTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RawNmeaViewerScreen(),
    );
  }
}
