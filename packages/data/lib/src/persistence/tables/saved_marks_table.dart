import 'package:drift/drift.dart';

/// A bója-könyvtár táblája (ADR 0032). Független, FK NÉLKÜL — túléli a
/// forrás-verseny törlését és átnevezését is (L1).
///
/// Előfordulás-napló (L2): az azonosság a `(name, latitudeE7,
/// longitudeE7, sourceRaceName)` négyes, amire unique index húzódik;
/// ütközéskor a data-réteg `INSERT OR IGNORE`-ral DoNothing-ol (L3), így
/// a meglévő sor `savedAt`-ja stabil marad. A koordináta egész E7-ben
/// (`fok × 1e7`) a pontos dedup-kulcsért (L4). A generált row-class
/// `SavedMarkRow`. PK nincs — az implicit rowid a fizikai kulcs, a
/// logikai azonosságot a unique index adja.
@DataClassName('SavedMarkRow')
@TableIndex(
  name: 'saved_mark_identity',
  unique: true,
  columns: {#name, #latitudeE7, #longitudeE7, #sourceRaceName},
)
class SavedMarks extends Table {
  TextColumn get name => text()();
  IntColumn get latitudeE7 => integer()();
  IntColumn get longitudeE7 => integer()();
  TextColumn get sourceRaceName => text()();
  DateTimeColumn get savedAt => dateTime()();
}
