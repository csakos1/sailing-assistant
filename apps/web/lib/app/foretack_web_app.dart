import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/localization_delegates.dart';
import 'package:foretack_web/auth/session_gate.dart';
import 'package:foretack_web/l10n/web_localizations.dart';
import 'package:foretack_web/race_log/race_log_screen.dart';

/// A webes archívum gyökér-widgetje (ADR 0047 D8).
///
/// A `ProviderScope` kívülről jön (a `main`-ből vagy a tesztből). A
/// navigáció `MaterialPageRoute`; deep-link és URL-állapot nincs (ADR 0047
/// D8, ADR 0048 Addendum 1 G1). A kezdőképernyő a napló.
///
/// A navigátor fölött a munkamenet-kapu áll (ADR 0051 Addendum 7 P2):
/// kijelentkezve a belépő képernyő látszik a navigátor helyett.
class ForetackWebApp extends StatelessWidget {
  /// A web gyökere.
  const ForetackWebApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => WebLocalizations.of(context)!.appTitle,
    debugShowCheckedModeBanner: false,
    theme: foretackTheme,
    localizationsDelegates: webLocalizationsDelegates,
    supportedLocales: WebLocalizations.supportedLocales,
    // A `child` a navigátor; `home` mellett sosem `null`.
    builder: (context, child) =>
        SessionGate(child: child ?? const SizedBox.shrink()),
    home: const RaceLogScreen(),
  );
}
