import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/telemetry_logger_provider.dart';

/// A Foretack app gyökér-widgetje.
///
/// A Riverpod `ProviderScope` kívülről jön (a `main`-ből), itt a
/// `MaterialApp`, a téma és a lokalizációs delegátorok élnek. A `home` a
/// versenylista (§14 Fázis 4).
///
/// A `telemetryLoggerProvider` egy `Provider<void>` mellékhatás-provider —
/// itt `watch`-oljuk eagerly, hogy aktív race alatt fusson a
/// telemetria-logolás (ADR 0009 D6); aktív race nélkül no-op.
///
/// Az `AppLocalizations.of(context)!` a fában a `MaterialApp` alatt
/// biztonságos: a delegátorokat itt regisztráljuk.
class ForetackApp extends ConsumerWidget {
  const ForetackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager watch: életre kelti a logger mellékhatás-providert.
    ref.watch(telemetryLoggerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: foretackTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RaceListScreen(),
    );
  }
}
