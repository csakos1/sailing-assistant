import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/theme.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_persistence_provider.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';
import 'package:phone/providers/telemetry_logger_provider.dart';

/// A Foretack app gyökér-widgetje.
///
/// A Riverpod `ProviderScope` kívülről jön (a `main`-ből), itt a
/// `MaterialApp`, a téma és a lokalizációs delegátorok élnek. A `home` a
/// versenylista (§14 Fázis 4).
///
/// Itt élnek eagerly a mellékhatás-providerek (`Provider<void>`), amiket
/// `watch` nélkül semmi nem építene fel:
///  - `telemetryLoggerProvider`: aktív race alatt logolja a nyers NMEA-t
///    (ADR 0009 D6); aktív race nélkül no-op.
///  - `activeRacePersistenceProvider`: induláskor visszatölti az aktív race-t,
///    és perzisztálja a kiválasztást (Fázis 5f, ADR 0011).
///
/// Az `AppLocalizations.of(context)!` a fában a `MaterialApp` alatt
/// biztonságos: a delegátorokat itt regisztráljuk.
class ForetackApp extends ConsumerWidget {
  const ForetackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager watch: életre kelti a mellékhatás-providereket.
    ref
      ..watch(telemetryLoggerProvider)
      ..watch(activeRacePersistenceProvider)
      ..watch(raceEngineLifecycleProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: foretackTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RaceListScreen(),
    );
  }
}
