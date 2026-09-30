import 'package:drift/drift.dart';

/// A versenyek webes eredmény-adatai (ADR 0047 D7 + Addendum 3 C3).
///
/// Versenyenként legfeljebb egy sor, a race UUID a kulcs. Idegen kulcs
/// nincs: a versenyek egy másik fájlban, az archívumban élnek (D5), a
/// kapcsolatot a szerver Dartban oldja fel. Ezért egy archívumból eltűnt
/// verseny sora itt árván maradhat; ez szándékos, mert az import soha nem
/// nyúl az annotációkhoz.
///
/// Row-class: `RaceAnnotationRow`, hogy ne ütközzön a szerződés
/// `RaceAnnotation` típusával.
@DataClassName('RaceAnnotationRow')
class RaceAnnotations extends Table {
  TextColumn get raceId => text()();
  IntColumn get overallPlace => integer().nullable()();
  IntColumn get overallFleetSize => integer().nullable()();
  IntColumn get classPlace => integer().nullable()();
  IntColumn get classFleetSize => integer().nullable()();
  TextColumn get summary => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};
}
