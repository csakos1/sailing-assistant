import 'dart:io';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// Tesztfixturak: valodi telefon-DB-k a data AppDatabase-evel, a phone
// RaceRepositoryImpl-jen at mentve. Igy a teszt a tenyleges Drift-semat
// hasznalja, kezzel irt CREATE TABLE nelkul.

final DateTime fixtureStart = DateTime.utc(2026, 7, 18, 9);

const Mark fixtureMark = Mark(
  sequence: 1,
  name: 'Tihany',
  position: Coordinate(latitude: 46.9125, longitude: 17.8890),
);

/// Befejezett verseny egy bojaval. Az utolso boja megkerulese maga
/// zarja a versenyt (Race.roundCurrentMark), ezert nincs kulon finish.
Race finishedFixtureRace(String id, {Duration offset = Duration.zero}) {
  final start = fixtureStart.add(offset);
  return Race.create(
    id: id,
    name: 'Verseny $id',
    marks: const [fixtureMark],
  ).start(at: start).roundCurrentMark(at: start.add(const Duration(hours: 3)));
}

/// Folyamatban levo verseny: az import kihagyja.
Race activeFixtureRace(String id) => Race.create(
  id: id,
  name: 'Futo $id',
  marks: const [fixtureMark],
).start(at: fixtureStart);

/// A [races] versenyek mentese egy friss DB-be, versenyenkent [samples]
/// telemetria- es snapshot-sorral, es egy track-stat cache-sorral.
Future<void> seedRaces(
  AppDatabase database,
  List<Race> races, {
  int samples = 3,
}) async {
  final repository = RaceRepositoryImpl(database);
  for (final race in races) {
    await repository.save(race);
    for (var i = 0; i < samples; i++) {
      final at = fixtureStart.add(Duration(seconds: i));
      await database
          .into(database.telemetryRecords)
          .insert(
            TelemetryRecordsCompanion.insert(
              raceId: race.id,
              timestamp: at,
              rawSentence: '\$GPRMC,$i',
            ),
          );
      await database
          .into(database.snapshotLogs)
          .insert(
            SnapshotLogsCompanion.insert(
              raceId: race.id,
              timestamp: at,
              snapshotJson: '{"i":$i}',
            ),
          );
    }
    await database
        .into(database.raceTrackStats)
        .insert(
          RaceTrackStatsCompanion.insert(
            raceId: race.id,
            distanceMeters: const Value(1000),
            maxSpeedMps: const Value(5),
            avgSpeedMps: const Value(3),
            sampleCount: samples,
            computedAt: fixtureStart,
          ),
        );
  }
}

/// Egy lezart telefon-DB a [file]-ban a [races] versenyekkel.
Future<void> writePhoneDatabase(
  File file,
  List<Race> races, {
  int samples = 3,
}) async {
  final database = AppDatabase(NativeDatabase(file));
  try {
    await seedRaces(database, races, samples: samples);
  } finally {
    await database.close();
  }
}

/// Sorok szama a [table] tablaban a [raceId] versenyhez.
Future<int> countRows(AppDatabase database, String table, String raceId) async {
  final row = await database
      .customSelect(
        'SELECT COUNT(*) AS c FROM "$table" WHERE race_id = ?',
        variables: [Variable.withString(raceId)],
      )
      .getSingle();
  return row.read<int>('c');
}
