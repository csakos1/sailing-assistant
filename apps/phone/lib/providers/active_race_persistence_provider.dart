import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// Az aktív race restart-túlélő perzisztenciája (Fázis 5f, ADR 0011 D4/D5).
///
/// Külön mellékhatás-provider (`Provider<void>`), hogy a tesztelt
/// ActiveRaceNotifier byte-azonos maradjon (OCP); a ForetackApp eager-watch-ol
/// rá (a telemetryLoggerProvider mintája). Induláskor EGYSZER restore-ol: a
/// tárolt id → RaceRepository.getRace → activeRace, no-clobber guarddal (ha a
/// user az async rés alatt már választott, nem írjuk felül). A kiválasztás
/// változásakor perzisztálja az id-t; finished vagy null race esetén TÖRLI
/// (nem támasztunk fel befejezett race-t restartkor).
final activeRacePersistenceProvider = Provider<void>((ref) {
  final settings = ref.read(settingsRepositoryProvider);

  // (a) Egyszeri restore. A state reaktívan frissül, ha van mit visszatölteni.
  unawaited(() async {
    if (ref.read(activeRaceProvider) != null) return;
    final id = await settings.readActiveRaceId();
    if (id == null) return;
    final race = await ref.read(raceRepositoryProvider).getRace(id);
    if (race != null && ref.read(activeRaceProvider) == null) {
      ref.read(activeRaceProvider.notifier).activeRace = race;
    }
  }());

  // (b) Kiválasztás-változás → perzisztálás (finished/null → törlés).
  ref.listen<Race?>(activeRaceProvider, (_, next) {
    final id = (next != null && next.status != RaceStatus.finished)
        ? next.id
        : null;
    unawaited(settings.writeActiveRaceId(id));
  });
});
