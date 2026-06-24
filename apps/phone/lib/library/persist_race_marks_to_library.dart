import 'package:domain/domain.dart';

/// A verseny bóyáit elmenti a bója-könyvtárba (ADR 0032 L5).
///
/// Best-effort: a hívó a verseny-mentés UTÁN hívja; egy könyvtár-írási hiba
/// NEM görgeti vissza a verseny-mentést (a verseny a forrás-igazság). A
/// `sourceRaceName` a verseny aktuális neve (edit-módban a frissített név), a
/// `savedAt` a hívó órájából — egy mentés egy időbélyeg minden bóyára.
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
    await repository.saveAll([
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
