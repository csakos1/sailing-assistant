import 'package:data/src/persistence/app_database.dart';
import 'package:data/src/persistence/repositories/race_repository_impl.dart';
import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

// The scheduled start and the start point in the races table (ADR 0055 D3).
void main() {
  late AppDatabase db;
  late RaceRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = RaceRepositoryImpl(db, now: () => DateTime(2026, 7, 29));
  });

  tearDown(() async {
    await db.close();
  });

  const mark = Mark(
    sequence: 1,
    name: 'Z1',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  const startPoint = StartPoint(
    name: 'Rajtvonal',
    position: Coordinate(latitude: 46.95, longitude: 17.88),
  );
  // Local DateTime: Drift stores unix seconds and reads them back as local
  // time, and DateTime == compares the isUtc flag too.
  final scheduledStartAt = DateTime(2026, 7, 30, 9);

  Race scheduledRace() => Race.create(
    id: 'race-1',
    name: 'Kekszalag',
    marks: const [mark],
    scheduledStartAt: scheduledStartAt,
    startPoint: startPoint,
  );

  Future<void> setColumns(String assignments) => db.customStatement(
    "UPDATE races SET $assignments WHERE id = 'race-1'",
  );

  group('round-trip', () {
    test('the scheduled start and the start point are read back', () async {
      // Arrange
      final race = scheduledRace();

      // Act
      await repository.save(race);
      final loaded = await repository.getRace('race-1');

      // Assert
      expect(loaded, equals(race));
    });

    test('a race without a schedule stays without one', () async {
      // Arrange
      final race = Race.create(
        id: 'race-1',
        name: 'Kekszalag',
        marks: const [mark],
      );

      // Act
      await repository.save(race);
      final loaded = await repository.getRace('race-1');

      // Assert
      expect(loaded?.scheduledStartAt, isNull);
      expect(loaded?.startPoint, isNull);
    });

    test('saving again clears a removed schedule and start point', () async {
      // Arrange
      await repository.save(scheduledRace());
      final cleared = scheduledRace().copyWith(
        clearScheduledStartAt: true,
        clearStartPoint: true,
      );

      // Act
      await repository.save(cleared);
      final loaded = await repository.getRace('race-1');

      // Assert
      expect(loaded?.scheduledStartAt, isNull);
      expect(loaded?.startPoint, isNull);
    });

    test('state transitions keep the schedule in the database', () async {
      // Arrange
      final started = scheduledRace().start(at: DateTime(2026, 7, 30, 9, 1));

      // Act
      await repository.save(started);
      final loaded = await repository.getRace('race-1');

      // Assert
      expect(loaded?.status, RaceStatus.active);
      expect(loaded?.scheduledStartAt, scheduledStartAt);
      expect(loaded?.startPoint, startPoint);
    });
  });

  group('an invalid start point row', () {
    for (final (description, assignments) in [
      ('a name without coordinates', 'start_point_latitude = NULL'),
      ('coordinates without a name', 'start_point_name = NULL'),
      ('an empty name', "start_point_name = ''"),
      ('a latitude out of range', 'start_point_latitude = 95.0'),
    ]) {
      test('$description loads the race without a start point', () async {
        // Arrange
        await repository.save(scheduledRace());
        await setColumns(assignments);

        // Act
        final loaded = await repository.getRace('race-1');

        // Assert: the race and its schedule survive, the start point does
        // not.
        expect(loaded?.name, 'Kekszalag');
        expect(loaded?.scheduledStartAt, scheduledStartAt);
        expect(loaded?.startPoint, isNull);
      });
    }

    test('the race list still loads with a broken row', () async {
      // Arrange
      await repository.save(scheduledRace());
      await setColumns('start_point_longitude = NULL');

      // Act
      final races = await repository.watchRaces().first;

      // Assert
      expect(races, hasLength(1));
      expect(races.single.startPoint, isNull);
    });
  });
}
