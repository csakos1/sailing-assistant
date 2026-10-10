import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

/// A versenyek táblája. A `statusIndex` a [RaceStatus] enum indexét tárolja
/// (`intEnum`). A generált row-class neve `RaceRow`, hogy ne ütközzön a
/// domain [Race] entitással.
@DataClassName('RaceRow')
class Races extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get statusIndex => intEnum<RaceStatus>()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get activeMarkIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  // A tervezett rajt és a rajthely (ADR 0055 D3, séma v6). A rajthely három
  // oszlopa vagy mind kitöltött, vagy mind üres; a repository olvasáskor
  // ellenőrzi.
  DateTimeColumn get scheduledStartAt => dateTime().nullable()();
  TextColumn get startPointName => text().nullable()();
  RealColumn get startPointLatitude => real().nullable()();
  RealColumn get startPointLongitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
