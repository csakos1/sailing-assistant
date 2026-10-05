import 'package:drift/drift.dart';

/// A trackes kézi versenyek régi mintái (ADR 0050 D3).
///
/// A track a kézi versenyhez tartozik, ezért él itt és nem az
/// `archive.sqlite`-ban: a telefon sémája érintetlen marad. Az időbélyeg
/// epoch-milliszekundum (UTC), a mennyiségek SI-egységben, mind
/// `null`-képes. A kulcs a verseny és az időbélyeg, így egy versenyen belül
/// egy pillanatnak egy mintája lehet, és az ablakos olvasás az index
/// mentén fut.
///
/// Row-class: `LegacyTrackSampleRow`.
@DataClassName('LegacyTrackSampleRow')
class LegacyTrackSamples extends Table {
  TextColumn get raceId => text()();
  IntColumn get timestampMs => integer()();
  RealColumn get latDeg => real().nullable()();
  RealColumn get lonDeg => real().nullable()();
  RealColumn get sogMps => real().nullable()();
  RealColumn get stwMps => real().nullable()();
  RealColumn get twsMps => real().nullable()();
  RealColumn get twdDeg => real().nullable()();
  RealColumn get polarTwsMps => real().nullable()();
  RealColumn get polarTwaDeg => real().nullable()();

  @override
  Set<Column> get primaryKey => {raceId, timestampMs};
}
