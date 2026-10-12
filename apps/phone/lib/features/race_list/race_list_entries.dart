import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// A lajstrom egy sora: a verseny, és hogy a mai napra van-e kiírva.
@immutable
class RaceListEntry {
  /// Egy lajstrom-bejegyzés.
  const RaceListEntry({required this.race, required this.isToday});

  /// A megjelenített verseny.
  final Race race;

  /// A tervezett rajt a helyi idő szerinti mai napra esik (ADR 0055 D5).
  final bool isToday;

  @override
  bool operator ==(Object other) =>
      other is RaceListEntry && other.race == race && other.isToday == isToday;

  @override
  int get hashCode => Object.hash(race, isToday);
}

/// A Versenyek fül sorai a lajstrom sorrendjében (ADR 0056 D4, makett 31a).
///
/// A befejezett versenyek kimaradnak (a Versenynapló fülön vannak, ADR
/// 0033). A sorrend:
/// 1. a folyamatban lévők, a bemenet sorrendjében;
/// 2. a mai vagy későbbi napra tervezett, el nem indult versenyek a rajt
///    szerint növekvőben; egyező rajtnál a bemenet sorrendje marad;
/// 3. a korábbi napra tervezett, de el nem indult (elmaradt) versenyek
///    ugyanígy — ne kerüljenek a mai verseny elé;
/// 4. a rajtidő nélküliek a bemenet sorrendjében.
///
/// A „ma" a [toLocal] szerinti helyi nap: a rajtidő és a [now] helyi
/// napja egyezik.
List<RaceListEntry> raceListEntriesOf({
  required List<Race> races,
  required DateTime now,
  required LocalWallClock toLocal,
}) {
  final localNow = toLocal(now);
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  DateTime dayOf(DateTime instant) {
    final local = toLocal(instant);
    return DateTime(local.year, local.month, local.day);
  }

  bool isToday(DateTime? scheduledStartAt) =>
      scheduledStartAt != null && dayOf(scheduledStartAt) == today;

  final active = races.where((race) => race.status == RaceStatus.active);
  final waiting = races.where((race) => race.status == RaceStatus.notStarted);
  final scheduled = [
    for (final (index, race) in waiting.indexed)
      if (race.scheduledStartAt case final start?) (index, start, race),
  ]..sort(_byStartThenIndex);
  final upcoming = scheduled.where((item) => !dayOf(item.$2).isBefore(today));
  final missed = scheduled.where((item) => dayOf(item.$2).isBefore(today));
  final undated = waiting.where((race) => race.scheduledStartAt == null);

  return [
    for (final race in active)
      RaceListEntry(race: race, isToday: isToday(race.scheduledStartAt)),
    for (final (_, start, race) in upcoming)
      RaceListEntry(race: race, isToday: isToday(start)),
    for (final (_, _, race) in missed)
      RaceListEntry(race: race, isToday: false),
    for (final race in undated) RaceListEntry(race: race, isToday: false),
  ];
}

// A `List.sort` nem stabil, ezért az egyező rajtidőt az eredeti index
// dönti el.
int _byStartThenIndex((int, DateTime, Race) a, (int, DateTime, Race) b) {
  final byStart = a.$2.compareTo(b.$2);
  return byStart != 0 ? byStart : a.$1.compareTo(b.$1);
}
