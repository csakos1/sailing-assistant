import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/annotation/annotation_repository.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  late AnnotationRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    repository = AnnotationRepository(databases.web);
  });

  tearDown(() => databases.close());

  const content = RaceAnnotationInput(
    overallPlace: 3,
    overallFleetSize: 24,
    classPlace: 1,
    classFleetSize: 9,
    summary: 'Gyenge szel.',
  );
  final savedAt = DateTime.utc(2026, 9, 30, 21, 15, 42, 123);

  group('AnnotationRepository', () {
    test('returns null for a race without annotation', () async {
      expect(await repository.get('r1'), isNull);
    });

    test(
      'upsert returns the stored row in UTC with second precision',
      () async {
        // ACT
        final saved = await repository.upsert(
          'r1',
          content,
          updatedAt: savedAt,
        );

        // ASSERT
        expect(saved.raceId, 'r1');
        expect(saved.content, content);
        expect(saved.updatedAt, DateTime.utc(2026, 9, 30, 21, 15, 42));
        expect(saved.updatedAt.isUtc, isTrue);
        expect(await repository.get('r1'), saved);
      },
    );

    test('upsert overwrites the previous annotation', () async {
      // ARRANGE
      await repository.upsert('r1', content, updatedAt: savedAt);

      // ACT
      await repository.upsert(
        'r1',
        const RaceAnnotationInput(overallPlace: 2),
        updatedAt: savedAt,
      );

      // ASSERT
      final stored = await repository.get('r1');
      expect(stored?.content, const RaceAnnotationInput(overallPlace: 2));
    });

    test('getAll maps annotations by race id', () async {
      // ARRANGE
      await repository.upsert('r1', content, updatedAt: savedAt);
      await repository.upsert(
        'r2',
        const RaceAnnotationInput(summary: 'x'),
        updatedAt: savedAt,
      );

      // ACT
      final all = await repository.getAll();

      // ASSERT
      expect(all.keys, unorderedEquals(<String>['r1', 'r2']));
      expect(all['r2']?.content.summary, 'x');
    });

    test('delete removes the row and tolerates a missing one', () async {
      // ARRANGE
      await repository.upsert('r1', content, updatedAt: savedAt);

      // ACT
      await repository.delete('r1');
      await repository.delete('missing');

      // ASSERT
      expect(await repository.get('r1'), isNull);
    });
  });
}
