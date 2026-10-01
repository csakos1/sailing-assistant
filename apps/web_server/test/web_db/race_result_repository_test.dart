import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  late RaceResultRepository repository;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    repository = RaceResultRepository(databases.web);
  });

  tearDown(() => databases.close());

  final content = RaceResultInput(
    classPlace: const Dsq(),
    classFleetSize: 9,
    overallPlace: const FinishPlace(3),
    overallFleetSize: 24,
    monohullPlace: const Dnf(),
    monohullFleetSize: 18,
    ysNumberHundredths: 7590,
    // A milliszekundum is megmarad: az idok epoch-ms-kent tarolodnak (I2).
    officialStart: DateTime.utc(2026, 7, 26, 9, 0, 0, 250),
    officialFinish: DateTime.utc(2026, 7, 26, 14, 24),
    prize: 'erem',
    summary: 'Gyenge szel.',
  );
  final savedAt = DateTime.utc(2026, 9, 30, 21, 15, 42, 123);

  group('RaceResultRepository', () {
    test('returns null for a race without a result', () async {
      expect(await repository.get('r1'), isNull);
    });

    test('round-trips every field, DNF and DSQ included', () async {
      // ACT
      final saved = await repository.upsert('r1', content, updatedAt: savedAt);

      // ASSERT
      expect(saved.content, content);
      expect(await repository.get('r1'), saved);
    });

    test('truncates the save time to seconds, in UTC', () async {
      final saved = await repository.upsert('r1', content, updatedAt: savedAt);

      expect(saved.updatedAt, DateTime.utc(2026, 9, 30, 21, 15, 42));
      expect(saved.updatedAt.isUtc, isTrue);
    });

    test('replaces the previous result on a second save', () async {
      // ARRANGE
      await repository.upsert('r1', content, updatedAt: savedAt);

      // ACT
      await repository.upsert(
        'r1',
        const RaceResultInput(overallPlace: FinishPlace(1)),
        updatedAt: savedAt,
      );

      // ASSERT
      final stored = await repository.get('r1');
      expect(
        stored?.content,
        const RaceResultInput(overallPlace: FinishPlace(1)),
      );
    });

    test('lists every result by race id', () async {
      // ARRANGE
      await repository.upsert('r1', content, updatedAt: savedAt);
      await repository.upsert(
        'm1',
        const RaceResultInput(prize: 'kupa'),
        updatedAt: savedAt,
      );

      // ACT
      final all = await repository.getAll();

      // ASSERT
      expect(all.keys, unorderedEquals(['r1', 'm1']));
      expect(all['m1']?.content.prize, 'kupa');
    });

    test('deletes a result, and deleting a missing one is fine', () async {
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
