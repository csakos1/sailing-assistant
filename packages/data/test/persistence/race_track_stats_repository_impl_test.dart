import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/race_track_stats_repository_impl.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late RaceTrackStatsRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = RaceTrackStatsRepositoryImpl(db);
    // A tábla FK-cascade-del hivatkozik a Races-re, ezért verseny-sor
    // nélkül minden beszúrás elhasalna. A státusz itt közömbös: a
    // befejezettség-szűrés a hívó dolga, nem a perzisztenciáé.
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-1',
            name: 'Teszt',
            statusIndex: RaceStatus.notStarted,
            createdAt: DateTime(2026, 6, 1, 10),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('a kiírt statisztikát változatlanul olvassa vissza', () async {
    // ARRANGE
    const stats = TrackStats(
      maxSpeedMps: 9.25,
      avgSpeedMps: 4.5,
      distanceMeters: 32000.5,
    );

    // ACT
    await repository.write(
      'race-1',
      stats,
      sampleCount: 13201,
      computedAt: DateTime(2026, 8, 8, 18, 40),
    );
    final read = await repository.read('race-1');

    // ASSERT
    expect(read, equals(stats));
  });

  test('ismeretlen versenyre null-t ad', () async {
    // ACT — a versenyhez sosem írtunk sort.
    final read = await repository.read('race-1');

    // ASSERT — a null itt „még nem számoltuk ki", nem hiba.
    expect(read, isNull);
  });

  test('ugyanarra a versenyre másodszor írva felülír', () async {
    // ARRANGE — egy korábbi, hiányos feltöltés eredménye.
    await repository.write(
      'race-1',
      const TrackStats(maxSpeedMps: 1, avgSpeedMps: 1, distanceMeters: 1),
      sampleCount: 10,
      computedAt: DateTime(2026, 7, 30),
    );

    // ACT — a teljes újraszámolás felülírja.
    const recomputed = TrackStats(
      maxSpeedMps: 9.25,
      avgSpeedMps: 4.5,
      distanceMeters: 32000.5,
    );
    await repository.write(
      'race-1',
      recomputed,
      sampleCount: 13201,
      computedAt: DateTime(2026, 8, 8),
    );

    // ASSERT — egyetlen sor maradt, az új értékekkel.
    expect(await repository.read('race-1'), equals(recomputed));
    expect(await db.select(db.raceTrackStats).get(), hasLength(1));
  });

  test('a hiányzó mezőket null-ként őrzi meg', () async {
    // ARRANGE — pozíció nélküli futam: nincs úthossz, nincs sebesség.
    const empty = TrackStats();

    // ACT
    await repository.write(
      'race-1',
      empty,
      sampleCount: 0,
      computedAt: DateTime(2026, 8, 8),
    );
    final read = await repository.read('race-1');

    // ASSERT — a nullák nem csapódnak nullára a round-trip során.
    expect(read, isNotNull);
    expect(read!.maxSpeedMps, isNull);
    expect(read.avgSpeedMps, isNull);
    expect(read.distanceMeters, isNull);
  });

  test('a verseny törlésekor a cascade a sorát is elviszi', () async {
    // ARRANGE
    await repository.write(
      'race-1',
      const TrackStats(maxSpeedMps: 9.25),
      sampleCount: 13201,
      computedAt: DateTime(2026, 8, 8),
    );

    // ACT
    await (db.delete(db.races)..where((row) => row.id.equals('race-1'))).go();

    // ASSERT — a beforeOpen bekapcsolja a PRAGMA foreign_keys-t, enélkül a
    // cascade némán nem futna, és árva sor maradna.
    expect(await repository.read('race-1'), isNull);
  });
}
