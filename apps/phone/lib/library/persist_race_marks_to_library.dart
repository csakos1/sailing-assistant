import 'package:domain/domain.dart';

/// A verseny bójáit és rajthelyét elmenti a bója-könyvtárba (ADR 0032 L5,
/// ADR 0055 D3).
///
/// A rajthely a bóják mellé kerül, hogy legközelebb a „Korábbi bóják" lapról
/// választható legyen; a könyvtár nem különbözteti meg (egy rajtvonal-bója
/// más versenyen pályabója is lehet).
///
/// Best-effort: a hívó a verseny-mentés UTÁN hívja; egy könyvtár-írási hiba
/// NEM görgeti vissza a verseny-mentést (a verseny a forrás-igazság). A
/// `sourceRaceName` a verseny aktuális neve (edit-módban a frissített név), a
/// `savedAt` a hívó órájából — egy mentés egy időbélyeg minden bójára.
///
/// Külön függvény (nem inline a két képernyőn): a két submit-ág (setup + edit)
/// közös, és `ref` nélkül — a hívó adja a repository-t —, így tisztán,
/// ProviderContainer nélkül tesztelhető.
Future<void> persistRaceMarksToLibrary({
  required MarkLibraryRepository repository,
  required Race race,
  required DateTime savedAt,
}) async {
  try {
    final startPoint = race.startPoint;
    await repository.saveAll([
      if (startPoint != null)
        SavedMark(
          name: startPoint.name,
          position: startPoint.position,
          sourceRaceName: race.name,
          savedAt: savedAt,
        ),
      for (final mark in race.marks)
        SavedMark(
          name: mark.name,
          position: mark.position,
          sourceRaceName: race.name,
          savedAt: savedAt,
        ),
    ]);
  } on Object catch (_) {
    // Best-effort (L5): a könyvtár-írás hibája szándékosan elnyelt — nem
    // blokkolja és nem görgeti vissza a verseny-mentést.
  }
}
