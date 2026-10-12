import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// A versenyrészlet alsó sávjának akciója (makett 32a–c,
/// `phone-ui-v1.md` §4). Befejezett versenyen nincs akció (`null`).
@immutable
sealed class DetailAction {
  const DetailAction();
}

/// Nem indult verseny, amit az engine a [scheduledStartAt]-kor magától
/// indít (ADR 0055 D6): „AUTOMATIKUS 09:00 | Rajt most" (32a).
final class DetailScheduledStart extends DetailAction {
  /// Egy tervezett rajt.
  const DetailScheduledStart(this.scheduledStartAt);

  /// A tervezett rajt pillanata.
  final DateTime scheduledStartAt;

  @override
  bool operator ==(Object other) =>
      other is DetailScheduledStart &&
      other.scheduledStartAt.isAtSameMomentAs(scheduledStartAt);

  @override
  int get hashCode => scheduledStartAt.millisecondsSinceEpoch.hashCode;
}

/// Nem indult verseny, ami csak kézzel indul: „Rajt" (32c).
final class DetailStart extends DetailAction {
  /// A kézi rajt.
  const DetailStart();
}

/// Folyamatban lévő verseny: „Cél" (32b).
final class DetailFinish extends DetailAction {
  /// A cél.
  const DetailFinish();
}

/// A [race] alsó sávjának akciója a [now] pillanatban.
///
/// Egy rajtidős verseny csak akkor kap „AUTOMATIKUS" cellát, ha az engine
/// még magától indítaná (felhasználói döntés, U6): a rajtidő ablaka
/// (`SelectInstrumentsRace.defaultLateStartWindow`) még nem járt le, és a
/// rajt napja nem korábbi a mainál — egy tegnapi versenyt a nap versenye
/// sosem választ ki (ADR 0055 D5), így az engine sem kapja meg. Minden más
/// el nem indult verseny a sima „Rajt"-ot kapja. A napot a [toLocal]
/// szerinti helyi idő adja.
DetailAction? detailActionOf({
  required Race race,
  required DateTime now,
  required LocalWallClock toLocal,
}) {
  return switch (race.status) {
    RaceStatus.finished => null,
    RaceStatus.active => const DetailFinish(),
    RaceStatus.notStarted => _startActionOf(race, now, toLocal),
  };
}

DetailAction _startActionOf(Race race, DateTime now, LocalWallClock toLocal) {
  final scheduledStartAt = race.scheduledStartAt;
  if (scheduledStartAt == null) return const DetailStart();
  final windowEnd = scheduledStartAt.add(
    SelectInstrumentsRace.defaultLateStartWindow,
  );
  if (!now.isBefore(windowEnd)) return const DetailStart();
  final startDay = _dayOf(toLocal(scheduledStartAt));
  if (startDay.isBefore(_dayOf(toLocal(now)))) return const DetailStart();
  return DetailScheduledStart(scheduledStartAt);
}

DateTime _dayOf(DateTime local) => DateTime(local.year, local.month, local.day);
