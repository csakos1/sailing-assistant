import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:phone/providers/engine_session_state.dart';

/// A hajó-kapcsolat a sáv Műszerek-cellájának felső élén (`phone-ui-v1.md`
/// §2).
enum InstrumentsLink {
  /// A próba keresi a hajót, vagy az engine még kapcsolódik (szaggatott él).
  searching,

  /// Az engine kapcsolódva van (teli `primary` él).
  connected,

  /// Nincs kapcsolat, vagy az engine áll (`outline` él, áthúzott jelvény).
  disconnected,
}

/// A sáv Műszerek-cellájának állapota (ADR 0056 D2, `phone-ui-v1.md` §2).
@immutable
class InstrumentsTabStatus {
  /// Állapot a [link] kapcsolattal, a nap versenyének [scheduledStartAt]
  /// rajtidejével és az [isLive] jelzővel.
  const InstrumentsTabStatus({
    required this.link,
    this.scheduledStartAt,
    this.isLive = false,
  });

  /// A hajó-kapcsolat.
  final InstrumentsLink link;

  /// A nap még el nem indult versenyének rajtideje helyi időben (a
  /// „09:00" címke); `null`, ha nincs ilyen, vagy aktív verseny fut.
  final DateTime? scheduledStartAt;

  /// Fut-e aktív verseny (az „ÉLŐ" címke és a kiemelt háttér).
  final bool isLive;

  @override
  bool operator ==(Object other) =>
      other is InstrumentsTabStatus &&
      other.link == link &&
      other.scheduledStartAt == scheduledStartAt &&
      other.isLive == isLive;

  @override
  int get hashCode => Object.hash(link, scheduledStartAt, isLive);

  @override
  String toString() =>
      'InstrumentsTabStatus($link, start: $scheduledStartAt, live: $isLive)';
}

/// A Műszerek-cella állapota a session, az engine kapcsolata, a kiválasztott
/// verseny és a nap versenye alapján.
///
/// Álló engine-nél nincs kapcsolat (a kézi „Leállítás" után is); futó
/// engine-nél a pillanatkép kapcsolata dönt (hiba = nincs kapcsolat), az
/// első pillanatképig „keresés". Aktív versenyen a rajtidő-címke helyett
/// az „ÉLŐ" áll. A [toLocal] a rajtidőt a sáv helyi órájára váltja.
InstrumentsTabStatus instrumentsTabStatusOf({
  required EngineSessionState session,
  required ConnectionStatus connection,
  required Race? selectedRace,
  required Race? dayRace,
  required LocalWallClock toLocal,
}) {
  final link = switch (session) {
    EngineStopped() => InstrumentsLink.disconnected,
    EngineProbing() => InstrumentsLink.searching,
    EngineRunning() => switch (connection) {
      Connected() => InstrumentsLink.connected,
      Connecting() => InstrumentsLink.searching,
      Disconnected() || ConnectionError() => InstrumentsLink.disconnected,
    },
  };
  final isLive = selectedRace?.status == RaceStatus.active;
  final scheduledStartAt = isLive ? null : dayRace?.scheduledStartAt;
  return InstrumentsTabStatus(
    link: link,
    scheduledStartAt: scheduledStartAt == null
        ? null
        : toLocal(scheduledStartAt),
    isLive: isLive,
  );
}
