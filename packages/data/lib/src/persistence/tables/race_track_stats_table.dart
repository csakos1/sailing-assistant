import 'package:data/src/persistence/tables/races_table.dart';
import 'package:drift/drift.dart';

/// Versenyenkénti track-összesítő gyorsítótár (ADR 0044 Addendum 4).
///
/// A versenynapló statisztika-csíkja e tábla nélkül tíz versenyre ~178 000
/// `snapshot_logs` sort járna be; a soronként ~8,3 KB-os JSON-blobok
/// felolvasása hideg page cache mellett másodpercekbe kerül. Egy befejezett
/// verseny track-statisztikája megváltoztathatatlan tény, ezért egyszer
/// kiszámoljuk, és itt materializáljuk.
///
/// A sorokat lusta feltöltés írja olvasáskor, NEM a motor: így a már
/// meglévő versenyek is visszatöltődnek, és a tábla független marad az
/// ADR 0045-től. Sor csak befejezett versenyre keletkezik.
///
/// Az `avgSpeedMps` akkor is szerepel, ha a napló nem mutatja: a
/// `SummarizeTrack` ugyanabban a bejárásban kiszámítja, így a tábla a
/// `TrackStats` teljes materializációja, és egy későbbi felhasználó nem
/// kényszerít újabb séma-migrációt egyetlen oszlopért. A három érték
/// nullable, mert pozíció nélküli vagy egyetlen mintás futamra nem
/// értelmezhető. FK-cascade a `Races`-re. Row-class: `RaceTrackStatsRow`.
@DataClassName('RaceTrackStatsRow')
class RaceTrackStats extends Table {
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  RealColumn get distanceMeters => real().nullable()();
  RealColumn get maxSpeedMps => real().nullable()();
  RealColumn get avgSpeedMps => real().nullable()();
  IntColumn get sampleCount => integer()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {raceId};
}
