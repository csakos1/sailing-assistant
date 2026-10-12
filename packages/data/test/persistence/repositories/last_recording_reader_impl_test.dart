import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase database;
  late SnapshotLoggerImpl logger;
  late LastRecordingReaderImpl reader;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    logger = SnapshotLoggerImpl(database);
    reader = LastRecordingReaderImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  // Parent race row: snapshot_logs.raceId references races.id.
  Future<void> insertRace(String id) {
    return database
        .into(database.races)
        .insert(
          RacesCompanion.insert(
            id: id,
            name: 'Test $id',
            statusIndex: RaceStatus.active,
            createdAt: DateTime.utc(2026, 7, 30),
          ),
        );
  }

  RaceSnapshot snapshotAt(DateTime tick) => RaceSnapshot(
    eventCount: 1,
    boatState: BoatState(lastUpdate: tick),
    connectionStatus: const Connected(),
    tickTime: tick,
    raceStatus: RaceStatus.active,
  );

  test('no recording gives null', () async {
    // Arrange
    await insertRace('race-1');

    // Act
    final latest = await reader('race-1');

    // Assert
    expect(latest, isNull);
  });

  test('the latest snapshot of the race wins, in UTC', () async {
    // Arrange
    await insertRace('race-1');
    await insertRace('race-2');
    final early = DateTime.utc(2026, 7, 30, 7);
    final lastTick = DateTime.utc(2026, 7, 31, 1, 30);
    await logger.log('race-1', snapshotAt(lastTick));
    await logger.log('race-1', snapshotAt(early));
    await logger.log(
      'race-2',
      snapshotAt(lastTick.add(const Duration(hours: 3))),
    );

    // Act
    final latest = await reader('race-1');

    // Assert
    expect(latest, lastTick);
    expect(latest?.isUtc, isTrue);
  });
}
