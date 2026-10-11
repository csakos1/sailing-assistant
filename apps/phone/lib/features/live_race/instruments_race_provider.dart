import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/live_race/instruments_race.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A Műszerek fülön versenyként mutatandó verseny, vagy `null` a szabad
/// módhoz (ADR 0056 D3, U3); a szabály az [instrumentsRaceOf]-é.
final AutoDisposeProvider<Race?> instrumentsRaceProvider =
    Provider.autoDispose<Race?>(
      (ref) => instrumentsRaceOf(
        selectedRace: ref.watch(activeRaceProvider),
        snapshot: ref.watch(raceSnapshotProvider),
      ),
    );
