import 'dart:convert';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SnapshotLoggerImpl logger;
  // A defenzív teszt lezárja a DB-t; a tearDown ne zárja újra.
  var dbClosedInTest = false;

  final tickTime = DateTime.utc(2025, 6, 1, 12, 0, 5);

  // Egy minimális snapshot a tesztekhez: a tickTime lesz a sor timestampje.
  RaceSnapshot snapshotAt(DateTime t) => RaceSnapshot(
    eventCount: 3,
    boatState: BoatState(lastUpdate: t),
    connectionStatus: const Connected(),
    tickTime: t,
  );

  setUp(() async {
    dbClosedInTest = false;
    db = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(db);
    // A snapshot_logs.raceId idegen kulcsa miatt egy race-sor kell a DB-ben;
    // ezt a setUp szúrja be (különben FK-sértés).
    await db
        .into(db.races)
        .insert(
          RacesCompanion.insert(
            id: 'race-1',
            name: 'Teszt',
            statusIndex: RaceStatus.notStarted,
            createdAt: DateTime(2025, 6, 1, 10),
          ),
        );
  });

  tearDown(() async {
    if (!dbClosedInTest) {
      await db.close();
    }
  });

  Future<List<SnapshotLogRow>> storedRows() => db.select(db.snapshotLogs).get();

  test('a snapshotot a raceId-vel és a tickTime-mal beszúrja', () async {
    // ARRANGE
    final snapshot = snapshotAt(tickTime);

    // ACT
    await logger.log('race-1', snapshot);

    // ASSERT — a sor a raceId-t, a tickTime-ot és a teljes JSON-blobot tartja.
    // A Drift DateTime-oszlop lokálisként olvas vissza, ezért az instant
    // azonosságát UTC-re normalizálva vetjük össze.
    final row = (await storedRows()).single;
    expect(row.raceId, 'race-1');
    expect(row.timestamp.toUtc(), tickTime);
    expect(row.snapshotJson, jsonEncode(snapshot.toJson()));
  });

  test('a tárolt blob visszaolvasva ekvivalens a snapshottal', () async {
    // ARRANGE + ACT
    final snapshot = snapshotAt(tickTime);
    await logger.log('race-1', snapshot);

    // ASSERT — round-trip: a blobból visszaépített snapshot értékei
    // egyeznek (a post-race elemzés ezt parse-olja majd).
    final row = (await storedRows()).single;
    final decoded = RaceSnapshot.fromJson(
      jsonDecode(row.snapshotJson) as Map<String, dynamic>,
    );
    expect(decoded.tickTime, snapshot.tickTime);
    expect(decoded.eventCount, snapshot.eventCount);
  });

  test('a race törlése cascade-del a snapshot-sorokat is viszi', () async {
    // ARRANGE
    await logger.log('race-1', snapshotAt(tickTime));
    expect(await storedRows(), hasLength(1));

    // ACT — a parent race törlése.
    await (db.delete(db.races)..where((r) => r.id.equals('race-1'))).go();

    // ASSERT — FK-cascade (PRAGMA foreign_keys = ON a beforeOpen-ben).
    expect(await storedRows(), isEmpty);
  });

  test('DB-hiba esetén a log nem dob (defenzív)', () async {
    // ARRANGE — a kapcsolat zárása után az insert hibára fut. A megosztott
    // db-t zárjuk (nem nyitunk másodikat -> nincs multiple-databases warn),
    // és jelezzük a tearDownnak, hogy ne zárja újra.
    await db.close();
    dbClosedInTest = true;

    // ACT + ASSERT — a log elnyeli a hibát, nem propagál.
    await expectLater(
      logger.log('race-1', snapshotAt(tickTime)),
      completes,
    );
  });

  test('dispose no-op, nem dob', () async {
    await expectLater(logger.dispose(), completes);
  });
}
