import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/shell/day_race_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/instruments_race_chooser.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_engine_lifecycle_provider.dart';
import 'package:phone/providers/settings_repository_provider.dart';

/// A Műszerek váltójának írója (ADR 0056 U4): a mentés után érvényteleníti
/// a tárolt választást (a sáv rajtidő-címkéje ebből számol), és a
/// lifecycle-lel azonnal újradönteti a nap versenyét.
final Provider<InstrumentsRaceChooser> instrumentsRaceChooserProvider =
    Provider<InstrumentsRaceChooser>((ref) {
      return InstrumentsRaceChooser(
        write: ref.watch(settingsRepositoryProvider).writeInstrumentsRaceChoice,
        now: ref.watch(clockProvider),
        toLocal: ref.watch(localWallClockProvider),
        onChosen: () {
          ref.invalidate(instrumentsRaceChoiceProvider);
          ref.read(raceEngineLifecycleProvider).onInstrumentsChoiceChanged();
        },
      );
    });
