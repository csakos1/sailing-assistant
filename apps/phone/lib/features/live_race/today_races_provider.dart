import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/local_wall_clock_provider.dart';
import 'package:phone/providers/race_list_provider.dart';
import 'package:phone/providers/tick_provider.dart';

/// A mai, még el nem indult, tervezett versenyek rajtidő szerint: a
/// Műszerek váltójának listája (34b-2a, ADR 0056 U4). Ugyanaz a szabály,
/// amelyből a nap versenye is választ (ADR 0055 D5).
///
/// A másodperces tick-kel számol újra, így egy lejárt ablakú verseny
/// magától kiesik a listából (a tick első üteméig az óra pillanata).
final AutoDisposeProvider<List<Race>> todayRacesProvider =
    Provider.autoDispose<List<Race>>(
      (ref) => const SelectInstrumentsRace().scheduledCandidates(
        races: ref.watch(raceListProvider).valueOrNull ?? const <Race>[],
        now: ref.watch(tickProvider).valueOrNull ?? ref.watch(clockProvider)(),
        toLocal: ref.watch(localWallClockProvider),
      ),
    );
