import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/race_repository_provider.dart';

/// Az összes verseny reaktív listája a lista-képernyőnek (ADR 0009 D4).
///
/// Tiszta projekció a RaceRepository.watchRaces() köré — nincs lokális
/// mutáció, ezért StreamProvider (nem Notifier). autoDispose: a stream
/// megszűnik, amint a lista-képernyő elhagyja a fát. A képernyő
/// `AsyncValue<List<Race>>`-t kap (loading/error/data).
///
/// Az explicit AutoDisposeStreamProvider típus tudatos: a
/// `StreamProvider.autoDispose<…>` factory más típust ad vissza, mint amit a
/// `StreamProvider` név sugall (specify_nonobvious_property_types).
final AutoDisposeStreamProvider<List<Race>> raceListProvider =
    StreamProvider.autoDispose<List<Race>>((ref) {
      return ref.watch(raceRepositoryProvider).watchRaces();
    });
