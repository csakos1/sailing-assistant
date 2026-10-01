import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:web_server/src/web_db/web_database.dart';

// Tesztfixturak az archivumhoz: valodi Drift-DB-k ideiglenes fajlokban,
// valodi RaceSnapshot-JSON-nel, hogy a RoundingSampleReaderImpl is
// dekodolni tudja (az importer-teszt {"i":0} blobjai ehhez nem elegek).

final DateTime archiveStart = DateTime.utc(2026, 7, 26, 11);

/// Befejezett verseny egy bojaval, [archiveStart]-tol eltolva.
Race finishedArchiveRace(String id, {Duration offset = Duration.zero}) {
  final start = archiveStart.add(offset);
  return Race.create(
    id: id,
    name: 'Archiv $id',
    marks: const [
      Mark(
        sequence: 1,
        name: 'Tihany',
        position: Coordinate(latitude: 46.9186, longitude: 17.9092),
      ),
    ],
  ).start(at: start).roundCurrentMark(at: start.add(const Duration(hours: 2)));
}

/// Egy pillanatkep a [tick]-ben; pozicio nelkul, ha [position] null, szel
/// nelkul, ha [twsMps] null. A szelirany foldrajzi (trueNorth).
RaceSnapshot archiveSnapshot({
  required DateTime tick,
  Coordinate? position,
  double? sogMps,
  double? twsMps,
  double twdDeg = 225,
}) => RaceSnapshot(
  eventCount: 1,
  boatState: BoatState(
    lastUpdate: tick,
    position: position,
    speedOverGround: sogMps == null ? null : Speed(metersPerSecond: sogMps),
  ),
  connectionStatus: const Connected(),
  tickTime: tick,
  raceStatus: RaceStatus.active,
  wind: twsMps == null
      ? null
      : WindData(
          apparentAngle: const Angle(degrees: 30),
          apparentSpeed: Speed(metersPerSecond: twsMps + 1),
          timestamp: tick,
          trueSpeedWater: Speed(metersPerSecond: twsMps),
          trueDirectionGround: Bearing(
            degrees: twdDeg,
            reference: BearingReference.trueNorth,
          ),
        ),
);

/// A [race] mentese az [archive]-ba, [positions] darab pozicios es egy
/// pozicio nelkuli pillanatkeppel, masodpercenkent a rajttol. Az i-edik
/// pozicios minta SOG-ja 3 + i, szele 4 + i m/s, 225 fokbol.
Future<void> seedArchiveRace(
  AppDatabase archive,
  Race race, {
  int positions = 3,
}) async {
  await RaceRepositoryImpl(archive).save(race);
  final logger = SnapshotLoggerImpl(archive);
  final start = race.startedAt ?? archiveStart;
  for (var i = 0; i < positions; i++) {
    await logger.log(
      race.id,
      archiveSnapshot(
        tick: start.add(Duration(seconds: i)),
        position: Coordinate(latitude: 46.9 + i * 0.001, longitude: 17.9),
        sogMps: 3.0 + i,
        twsMps: 4.0 + i,
      ),
    );
  }
  await logger.log(
    race.id,
    archiveSnapshot(tick: start.add(Duration(seconds: positions))),
  );
}

/// Egy archivum- es egy webes DB egy ideiglenes konyvtarban.
final class ArchiveDatabases {
  ArchiveDatabases._(this.directory, this.archive, this.web);

  /// Friss, ures DB-k egy uj ideiglenes konyvtarban.
  static Future<ArchiveDatabases> open() async {
    final directory = await Directory.systemTemp.createTemp(
      'foretack_archive_test',
    );
    return ArchiveDatabases._(
      directory,
      AppDatabase(NativeDatabase(File('${directory.path}/archive.sqlite'))),
      WebDatabase(NativeDatabase(File('${directory.path}/web.sqlite'))),
    );
  }

  final Directory directory;
  final AppDatabase archive;
  final WebDatabase web;

  Future<void> close() async {
    await archive.close();
    await web.close();
    await directory.delete(recursive: true);
  }
}
