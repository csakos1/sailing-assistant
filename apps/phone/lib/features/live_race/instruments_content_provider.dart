import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/features/live_race/instruments_content.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/race_snapshot_provider.dart';

/// A Műszerek fül tartalma (ADR 0056 D3, U4); a szabály az
/// [instrumentsContentOf]-é. Amíg a versenylista tölt, egy rajt előtti
/// engine-verseny a szabad módot mutatja.
final AutoDisposeProvider<InstrumentsContent> instrumentsContentProvider =
    Provider.autoDispose<InstrumentsContent>(
      (ref) => instrumentsContentOf(
        selectedRace: ref.watch(activeRaceProvider),
        snapshot: ref.watch(raceSnapshotProvider),
        races: ref.watch(raceListProvider).valueOrNull ?? const <Race>[],
      ),
    );
