import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/engine_service_error_provider.dart';
import 'package:phone/providers/polar_provider.dart';
import 'package:phone/providers/race_engine_host_provider.dart';
import 'package:phone/providers/race_engine_session_provider.dart';
import 'package:shared/shared.dart';

/// A háttér-engine életciklusát a session-flaghez és a verseny státusz-
/// átmeneteihez köti (ADR 0017 A12/A13). Mellékhatás-provider (`Provider<void>`):
/// az app-gyökér eager-watch-olja (a `telemetryLoggerProvider` mintája).
///
/// (1) A session-flag billenésére indít/állít: `host.start(activeRace)` a
/// `ServiceRequestFailure`-t az `engineServiceErrorProvider`-be teszi;
/// `host.stop()` + a hiba nullázása. (2) A verseny in-place státusz-átmeneteire
/// (notStarted→active, active→finished) minimális parancsot küld az engine-nek,
/// ha a session aktív — a teljes Race NEM kel át futás közben (az index az
/// engine-é, A10). A kiválasztás-csere (más race / null) NEM parancs.
final raceEngineLifecycleProvider = Provider<void>((ref) {
  final host = ref.watch(raceEngineHostProvider);

  ref
    ..listen<bool>(raceEngineSessionProvider, (_, active) {
      if (active) {
        final race = ref.read(activeRaceProvider);
        if (race == null) return;
        unawaited(() async {
          final polar = await _loadPolar(ref);
          final error = await host.start(race, polar: polar);
          ref.read(engineServiceErrorProvider.notifier).state = error;
        }());
      } else {
        ref.read(engineServiceErrorProvider.notifier).state = null;
        unawaited(host.stop());
      }
    })
    ..listen<Race?>(activeRaceProvider, (prev, next) {
      if (!ref.read(raceEngineSessionProvider)) return;
      if (prev == null || next == null || prev.id != next.id) return;
      if (prev.status == next.status) return;
      final startedAt = next.startedAt;
      final finishedAt = next.finishedAt;
      if (next.status == RaceStatus.active && startedAt != null) {
        host.sendStartCommand(startedAt);
      } else if (next.status == RaceStatus.finished && finishedAt != null) {
        host.sendFinishCommand(finishedAt);
        // A cél terminális esemény: a sessiont is lezárjuk, így a
        // háttér-engine leáll és a foreground-service értesítés
        // eltűnik (ADR 0017 A12). A navigáció/háttérbe tétel továbbra
        // sem állít le. [d5: graceful finish-then-stop a telemetria
        // lezárásához a leállás előtt.]
        ref.read(raceEngineSessionProvider.notifier).stop();
      }
    });
});

/// A polár betöltése a `polarProvider`-ből; hiba/hiányzó polár → `null`
/// (a háttér-engine null-polárral fut, a cél-sebesség `null`).
Future<Polar?> _loadPolar(Ref ref) async {
  final result = await ref.read(polarProvider.future);
  return switch (result) {
    Ok(:final value) => value,
    Err() => null,
  };
}
