import 'package:data/src/persistence/tables/races_table.dart';
import 'package:drift/drift.dart';

/// Egy verseny bóyái. PK a `{raceId, sequence}` páros; a `raceId` FK a
/// [Races]-re, cascade törléssel. A generált row-class `MarkRow`.
@DataClassName('MarkRow')
class Marks extends Table {
  TextColumn get raceId =>
      text().references(Races, #id, onDelete: KeyAction.cascade)();
  IntColumn get sequence => integer()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get roundedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {raceId, sequence};
}
