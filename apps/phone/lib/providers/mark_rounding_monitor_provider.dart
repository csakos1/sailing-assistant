import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/providers/active_race_provider.dart';
import 'package:phone/providers/boat_state_provider.dart';

/// Az aktív bója automatikus továbblépését vezérlő figyelő (§8.4).
///
/// A [boatStateProvider] pozíció-frissítéseit hallgatja, és a domain §7.7
/// [MarkRoundingDetector]-rel detektálja a megkerülést (a hajó a küszöbön
/// belülre ér, majd a hiszterézist meghaladva távolodik). Megkerüléskor az
/// [ActiveRaceNotifier.roundCurrentMark]-ot hívja, és reseteli a detektort a
/// következő bójához.
///
/// **Élettartam.** autoDispose `Provider<void>` — a `LiveRaceScreen`
/// eager-watch-olja, így a screen mountjával él és unmountjával eldobódik. A
/// screen a `boatState`-en át úgyis felépíti a connectiont; a monitor erre ül
/// rá (ADR 0010 D5 lusta connection).
///
/// **Status-gate.** Csak `status == active` alatt léptet: a `roundCurrentMark`
/// `active→...` átmenet, és rajt előtt a mark[0] körüli manőver nem
/// továbblépés. notStarted alatt a detektort sem etetjük, így rajt után hamis
/// trigger nélkül indul a minimum-követés.
final markRoundingMonitorProvider = AutoDisposeProvider<void>((ref) {
  final detector = MarkRoundingDetector();

  ref.listen(boatStateProvider, (_, current) {
    final race = ref.read(activeRaceProvider);
    if (race == null || race.status != RaceStatus.active) return;
    final position = current.position;
    if (position == null) return;
    final activeMark = race.activeMarkOrNull;
    if (activeMark == null) return;

    if (detector.tick(position, activeMark)) {
      unawaited(ref.read(activeRaceProvider.notifier).roundCurrentMark());
      detector.reset();
    }
  });
});
