import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  late ManualRaceRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    repository = ManualRaceRepository(databases.web);
  });

  tearDown(() => databases.close());

  final lelle = ManualRaceInput(
    name: 'IX. Lelle Kupa',
    date: CalendarDate.tryParse('2025-08-23')!,
    distanceMeters: 9800,
    maxSpeedMps: 3.55,
    avgWindMps: 1.6,
    maxWindMps: 3.3,
    windPoint: CompassPoint.southEast,
  );
  final createdAt = DateTime.utc(2026, 10, 1, 9);
  final editedAt = DateTime.utc(2026, 10, 2, 10);

  group('ManualRaceRepository', () {
    test('round-trips an inserted race with its compass point', () async {
      // ACT
      final record = await repository.insert('m1', lelle, now: createdAt);

      // ASSERT
      expect(record.input, lelle);
      expect(record.createdAt, createdAt);
      expect(await repository.get('m1'), record);
    });

    test('stores a race without optional values', () async {
      // ARRANGE
      final bare = ManualRaceInput(
        name: 'Edzes',
        date: CalendarDate.tryParse('2021-05-01')!,
      );

      // ACT
      final record = await repository.insert('m2', bare, now: createdAt);

      // ASSERT
      expect(record.input, bare);
    });

    test('updates the race and keeps the creation time', () async {
      // ARRANGE
      await repository.insert('m1', lelle, now: createdAt);
      final renamed = ManualRaceInput(name: 'X. Lelle Kupa', date: lelle.date);

      // ACT
      final record = await repository.update('m1', renamed, now: editedAt);

      // ASSERT
      expect(record?.input, renamed);
      expect(record?.createdAt, createdAt);
      expect(record?.updatedAt, editedAt);
    });

    test('updates nothing for an unknown id', () async {
      expect(await repository.update('missing', lelle, now: editedAt), isNull);
    });

    test('deletes a race and reports whether it existed', () async {
      // ARRANGE
      await repository.insert('m1', lelle, now: createdAt);

      // ACT + ASSERT
      expect(await repository.delete('m1'), isTrue);
      expect(await repository.delete('m1'), isFalse);
      expect(await repository.getAll(), isEmpty);
    });
  });
}
