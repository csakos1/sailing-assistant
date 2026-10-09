import 'package:drift/drift.dart';

/// A versenyek eredménye (ADR 0048 D3, D9 + Addendum 3 I2).
///
/// Versenyenként legfeljebb egy sor, a verseny azonosítója a kulcs, akár
/// telemetriás, akár kézi. Idegen kulcs nincs: a telemetriás versenyek egy
/// másik fájlban, az archívumban élnek (ADR 0047 D5).
///
/// A helyezés két oszlop: a szám (`*_place`) vagy a státusz (`*_status`,
/// `'dnf'` / `'dsq'`), legfeljebb az egyik kitöltve. A hivatalos idők
/// epoch-milliszekundumok, nem Drift `dateTime`-ok, hogy ne csonkuljanak
/// (I2).
///
/// Row-class: `RaceResultRow`, hogy ne ütközzön a szerződés `RaceResult`
/// típusával.
@DataClassName('RaceResultRow')
class RaceResults extends Table {
  TextColumn get raceId => text()();
  IntColumn get classPlace => integer().nullable()();
  TextColumn get classStatus => text().nullable()();
  IntColumn get classFleetSize => integer().nullable()();
  IntColumn get overallPlace => integer().nullable()();
  TextColumn get overallStatus => text().nullable()();
  IntColumn get overallFleetSize => integer().nullable()();
  IntColumn get monohullPlace => integer().nullable()();
  TextColumn get monohullStatus => text().nullable()();
  IntColumn get monohullFleetSize => integer().nullable()();
  IntColumn get ysNumberHundredths => integer().nullable()();
  IntColumn get officialStartMs =>
      integer().named('official_start').nullable()();
  IntColumn get officialFinishMs =>
      integer().named('official_finish').nullable()();
  TextColumn get prize => text().nullable()();
  TextColumn get summary => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};

  // A drift_dev a megszorításokat a forrásból olvassa ki, ezért ezek
  // egyszerű szöveg-literálok, nem generált lista.
  @override
  List<String> get customConstraints => [
    "CHECK (class_status IS NULL OR class_status IN ('dnf', 'dsq'))",
    "CHECK (overall_status IS NULL OR overall_status IN ('dnf', 'dsq'))",
    "CHECK (monohull_status IS NULL OR monohull_status IN ('dnf', 'dsq'))",
    'CHECK (class_place IS NULL OR class_status IS NULL)',
    'CHECK (overall_place IS NULL OR overall_status IS NULL)',
    'CHECK (monohull_place IS NULL OR monohull_status IS NULL)',
  ];
}
