import 'package:domain/src/entities/saved_mark.dart';

/// A bója-könyvtár perzisztencia-kontraktusa (ADR 0032 L6).
///
/// ISP: szándékosan KÜLÖN a `RaceRepository`-tól — a könyvtár írása és
/// olvasása független a versenyek életciklusától. Clean Architecture:
/// a domain csak az absztrakciót ismeri, a konkrét implementáció
/// (Drift/SQLite) a data rétegben él, a függőség befelé mutat (DIP).
///
/// A mentés best-effort (ADR 0032 L5): a hívó a verseny-mentés UTÁN
/// hívja, és egy esetleges írás-hiba nem görgeti vissza a verseny
/// mentését — a verseny a forrás-igazság.
abstract class MarkLibraryRepository {
  /// Elment több [SavedMark]-ot a könyvtárba. Idempotens az
  /// azonosság-négyesre (`name`, E7-pozíció, `sourceRaceName`): a
  /// data-réteg `DoNothing`-gal kezeli az ütközést (ADR 0032 L3).
  Future<void> saveAll(Iterable<SavedMark> marks);

  /// A könyvtár összes bójájának reaktív streamje, [SavedMark.savedAt]
  /// szerint csökkenőben (legutóbbi elöl) — a picker ezt fogyasztja.
  Stream<List<SavedMark>> watchAll();
}
