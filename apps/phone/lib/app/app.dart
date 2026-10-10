import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/app/localization_delegates.dart';
import 'package:phone/features/race_list/race_list_screen.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/active_race_persistence_provider.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';

/// A Foretack app gyökér-widgetje.
///
/// A Riverpod `ProviderScope` kívülről jön (a `main`-ből), itt a
/// `MaterialApp`, a téma és a lokalizációs delegátorok élnek. A `home` a
/// versenylista (§14 Fázis 4).
///
/// Itt élnek eagerly a mellékhatás-providerek (`Provider<void>`), amiket
/// `watch` nélkül semmi nem építene fel:
///  - `activeRacePersistenceProvider`: induláskor visszatölti az aktív race-t,
///    és perzisztálja a kiválasztást (Fázis 5f, ADR 0011).
///  - `raceEngineLifecycleProvider`: a háttér-engine indítása és leállítása
///    (ADR 0017 A12/A13). A nyers NMEA telemetriáját az engine írja
///    (ADR 0017 D8), a UI-izolátum nem.
///
/// Az `AppLocalizations.of(context)!` a fában a `MaterialApp` alatt
/// biztonságos: a delegátorokat itt regisztráljuk.
class ForetackApp extends ConsumerWidget {
  const ForetackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eager watch: életre kelti a mellékhatás-providereket.
    ref
      ..watch(activeRacePersistenceProvider)
      ..watch(raceEngineLifecycleProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: foretackTheme,
      localizationsDelegates: phoneLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RaceListScreen(),
    );
  }
}
