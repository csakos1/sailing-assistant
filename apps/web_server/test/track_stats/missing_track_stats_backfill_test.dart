import 'dart:io';

import 'package:data/data.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/import/race_importer.dart';
import 'package:web_server/src/track_stats/missing_track_stats_backfill.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  final computedAt = DateTime.utc(2026, 10);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async => databases = await ArchiveDatabases.open());

  tearDown(() => databases.close());

  MissingTrackStatsBackfill backfillOf(AppDatabase archive) =>
      MissingTrackStatsBackfill(archive: archive, now: () => computedAt);

  group('MissingTrackStatsBackfill', () {
    test('fills only races without a track-stats row', () async {
      // ARRANGE
      final archive = databases.archive;
      await seedArchiveRace(archive, finishedArchiveRace('cached'));
      await seedArchiveRace(
        archive,
        finishedArchiveRace('missing', offset: const Duration(days: 1)),
        withStats: false,
      );

      // ACT
      final filled = await backfillOf(archive)();

      // ASSERT
      expect(filled, ['missing']);
      final repository = RaceTrackStatsRepositoryImpl(archive);
      final computed = await repository.read('missing');
      expect(computed, isNotNull);
      expect(computed?.distanceMeters, greaterThan(0));
      expect(computed?.maxSpeedMps, 5);
      // A cache-elt sort nem irja felul.
      expect((await repository.read('cached'))?.distanceMeters, 1234);
    });

    test('is a no-op on an archive where every race has stats', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('cached'));

      // ACT + ASSERT
      expect(await backfillOf(databases.archive)(), isEmpty);
    });
  });

  group('RaceImporter with backfill', () {
    test('an imported race without a phone-side row gets one', () async {
      // ARRANGE: telefon-DB, amelyben a verseny befejezett, de a naplot
      // meg nem nyitottak meg, tehat nincs track-stat sora.
      final phoneFile = File('${databases.directory.path}/phone.sqlite');
      final phone = AppDatabase(NativeDatabase(phoneFile));
      await seedArchiveRace(
        phone,
        finishedArchiveRace('fresh'),
        withStats: false,
      );
      await phone.close();
      final importer = RaceImporter(
        archive: databases.archive,
        tempRoot: databases.directory,
        backfill: backfillOf(databases.archive),
      );

      // ACT
      final result = await importer(database: phoneFile);

      // ASSERT
      expect(result, isA<Ok<ImportReport, ImportRejection>>());
      final stats = await RaceTrackStatsRepositoryImpl(
        databases.archive,
      ).read('fresh');
      expect(stats, isNotNull);
    });
  });
}
