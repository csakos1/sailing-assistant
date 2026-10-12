import 'dart:async';
import 'dart:developer' as developer;

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/race_start_signal_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// Az aktív race restart-túlélő perzisztenciája (Fázis 5f, ADR 0011 D4/D5).
///
/// Külön mellékhatás-provider (`Provider<void>`), hogy a tesztelt
/// ActiveRaceNotifier byte-azonos maradjon (OCP); a ForetackApp eager-watch-ol
/// rá. Induláskor EGYSZER restore-ol: a
/// tárolt id → RaceRepository.getRace → activeRace, no-clobber guarddal (ha a
/// user az async rés alatt már választott, nem írjuk felül). Egy futó
/// (`active`) verseny visszatöltése a Műszerekre váltás jelzését is adja
/// (`raceStartSignalProvider`, ADR 0056 U3): egy verseny közbeni
/// app-újraindítás után a versenyző a műszereket keresi. Csak akkor, ha a
/// verseny folytatható (`IsRaceResumable`, ADR 0054 E3): egy napokkal
/// korábban félbehagyott verseny miatt az app nem ugrik minden indításkor
/// a Műszerekre. A kiválasztás
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
      // A felvétel olvasása alatt a user mást választhatott: csak a még
      // kiválasztott verseny jelezhet.
      if (await _isResumable(ref, race) &&
          ref.read(activeRaceProvider)?.id == race.id) {
        ref.read(raceStartSignalProvider.notifier).signal(race.id);
      }
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

// Folytatható-e a visszatöltött verseny (ugyanaz a szabály, mint a
// lifecycle-é). A legutóbbi felvétel olvasási hibájánál csak a rajtidő
// számít, mint ott.
Future<bool> _isResumable(Ref ref, Race race) async {
  if (race.status != RaceStatus.active) return false;
  DateTime? lastRecordedAt;
  try {
    lastRecordedAt = await ref.read(lastRecordingReaderProvider)(race.id);
  } on Object catch (error) {
    developer.log('last recording read failed: $error', name: 'Restore');
  }
  return const IsRaceResumable()(
    race: race,
    lastRecordedAt: lastRecordedAt,
    now: ref.read(clockProvider)(),
  );
}
