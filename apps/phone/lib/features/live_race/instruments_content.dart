import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// A Műszerek fül tartalma (ADR 0056 D3): szabad mód (34a), rajt előtt
/// (34b) vagy verseny (34c).
@immutable
sealed class InstrumentsContent {
  const InstrumentsContent();
}

/// Szabad mód: az engine nem vezet versenyt, vagy nem fut.
final class InstrumentsFreeMode extends InstrumentsContent {
  /// A szabad mód.
  const InstrumentsFreeMode();
}

/// Rajt előtt: az engine egy még el nem indult versenyt vezet a
/// rajthelyre (ADR 0055 D2).
final class InstrumentsPreStart extends InstrumentsContent {
  /// A [race] rajt előtti nézete.
  const InstrumentsPreStart(this.race);

  /// Az engine rajt előtti versenye.
  final Race race;

  @override
  bool operator ==(Object other) =>
      other is InstrumentsPreStart && other.race == race;

  @override
  int get hashCode => Object.hash(InstrumentsPreStart, race);
}

/// Verseny: az engine a kiválasztott, aktív versenyt futtatja.
final class InstrumentsRacing extends InstrumentsContent {
  /// A [race] versenyes nézete.
  const InstrumentsRacing(this.race);

  /// A futó verseny.
  final Race race;

  @override
  bool operator ==(Object other) =>
      other is InstrumentsRacing && other.race == race;

  @override
  int get hashCode => Object.hash(InstrumentsRacing, race);
}

/// A Műszerek fül tartalma az engine állapotából (ADR 0056 U3, U4).
///
/// Az engine pillanatképe dönt, nem a UI kiválasztása (a kiválasztás egy
/// Cél után a befejezett versenyen marad):
///
/// - **verseny**, ha a [selectedRace] aktív, és a pillanatkép ugyanezt az
///   id-t hordozza aktívként, vagy még rajt előttiként: egy „Rajt most"
///   után az engine első aktív pillanatképéig (~1 mp) a fül nem villan a
///   rajt előtti nézetre;
/// - **verseny** akkor is, ha az engine egy, a [races] között meglévő
///   versenyt futtat aktívként, de a kiválasztás más: az engine magától
///   rajtolt a tervezett időben (ADR 0055 D6), és a DB-be vétel még tart,
///   vagy egy régi, elfelejtett aktív verseny maradt kiválasztva;
/// - **rajt előtt**, ha a pillanatkép egy el nem indult versenyt hordoz,
///   és a [races] között ez a verseny még el nem indult (a friss, a
///   DB-ben szerkesztett példány megy tovább);
/// - minden más **szabad mód**: verseny nélkül, Cél után, álló engine
///   mellett (nincs pillanatkép), és egy kézi „Rajt" után az engine első
///   pillanatképéig, ha az engine addig szabad módban futott.
InstrumentsContent instrumentsContentOf({
  required Race? selectedRace,
  required RaceSnapshot? snapshot,
  required List<Race> races,
}) {
  final raceId = snapshot?.raceId;
  if (snapshot == null || raceId == null) return const InstrumentsFreeMode();
  final engineStatus = snapshot.raceStatus;
  if (selectedRace != null &&
      selectedRace.id == raceId &&
      selectedRace.status == RaceStatus.active &&
      (engineStatus == RaceStatus.active ||
          engineStatus == RaceStatus.notStarted)) {
    return InstrumentsRacing(selectedRace);
  }
  for (final race in races) {
    if (race.id != raceId || race.status == RaceStatus.finished) continue;
    return switch (engineStatus) {
      RaceStatus.active => InstrumentsRacing(race),
      RaceStatus.notStarted when race.status == RaceStatus.notStarted =>
        InstrumentsPreStart(race),
      _ => const InstrumentsFreeMode(),
    };
  }
  return const InstrumentsFreeMode();
}
