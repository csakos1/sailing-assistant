import 'package:data/data.dart';
import 'package:domain/domain.dart';

/// A Műszerek fülön versenyként (1c) mutatandó verseny, vagy `null`, ha a
/// fül a szabad módot (34a) mutatja (ADR 0056 D3, U3).
///
/// Az engine állapota dönt, nem a UI kiválasztása: az 1c csak akkor jár,
/// ha az engine épp **ezt** a versenyt futtatja aktívként (a pillanatkép
/// `raceId`-ja és `raceStatus`-a), és a UI szerint is aktív. A kiválasztás
/// egy Cél után a befejezett versenyen marad, miközben az engine már szabad
/// módban fut; a UI-ból döntve ilyenkor egy halott 1c látszana.
///
/// Egy kézi „Rajt" és az engine első aktív pillanatképe között (~1 mp) a
/// fül még a szabad módot mutatja; egy kézi „Leállítás" után (nincs
/// pillanatkép) a futó verseny is a szabad mód „Leállítva" állapotát. A
/// rajt előtti engine-verseny (34b) az U4-ig szintén a szabad mód.
Race? instrumentsRaceOf({
  required Race? selectedRace,
  required RaceSnapshot? snapshot,
}) {
  if (selectedRace == null || snapshot == null) return null;
  final isEngineRacing =
      snapshot.raceStatus == RaceStatus.active &&
      snapshot.raceId == selectedRace.id;
  return isEngineRacing && selectedRace.status == RaceStatus.active
      ? selectedRace
      : null;
}
