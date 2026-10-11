import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/instruments_race_selector.dart';
import 'package:phone/providers/last_recording_reader_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_repository_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// A „nap versenyének" kiválasztója (ADR 0055 D5, T4) a DB-hez, a
/// beállításokhoz és a UI kiválasztásához kötve. Az óra a `clockProvider`
/// (rendszeróra, ADR 0055 „Pontosítás (T4)"); a helyi nap a
/// `localWallClockProvider`.
final Provider<InstrumentsRaceSelector> instrumentsRaceSelectorProvider =
    Provider<InstrumentsRaceSelector>((ref) {
      final repository = ref.watch(raceRepositoryProvider);
      final settings = ref.watch(settingsRepositoryProvider);
      return InstrumentsRaceSelector(
        readRaces: () => repository.watchRaces().first,
        readSelectedRace: () => ref.read(activeRaceProvider),
        readLastRecordingAt: ref.watch(lastRecordingReaderProvider),
        readChoice: settings.readInstrumentsRaceChoice,
        now: ref.watch(clockProvider),
        toLocal: ref.watch(localWallClockProvider),
      );
    });
