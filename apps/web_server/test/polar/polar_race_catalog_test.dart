import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_track_sample.dart';
import 'package:web_server/src/polar/polar_race.dart';
import 'package:web_server/src/polar/polar_race_catalog.dart';
import 'package:web_server/src/web_db/legacy_track_repository.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

import '../support/archive_fixture.dart';

void main() {
  late ArchiveDatabases databases;
  late RaceResultRepository results;
  late ManualRaceRepository manualRaces;
  late LegacyTrackRepository tracks;
  late PolarRaceCatalog catalog;
  final now = DateTime.utc(2026, 10, 6, 8);
  final manualStart = DateTime.utc(2023, 7, 1, 10);
  // A `!` biztonsagos: letezo nap.
  final manualDay = CalendarDate.tryParse('2023-07-01')!;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    results = RaceResultRepository(databases.web);
    manualRaces = ManualRaceRepository(databases.web);
    tracks = LegacyTrackRepository(databases.web);
    catalog = PolarRaceCatalog(
      races: RaceRepositoryImpl(databases.archive),
      results: results,
      manualRaces: manualRaces,
      tracks: tracks,
    );
  });

  tearDown(() => databases.close());

  // Kezi verseny 2023-07-01-en; opcionalisan trackkel es hivatalos idovel.
  Future<void> addManualRace(
    String id, {
    required bool hasTrack,
    required bool hasOfficialTimes,
  }) async {
    await manualRaces.insert(
      id,
      ManualRaceInput(name: 'Kezi $id', date: manualDay),
      now: now,
    );
    if (hasTrack) {
      await tracks.replace(id, [
        LegacyTrackSample(timestamp: manualStart, stwMps: 3),
      ]);
    }
    if (hasOfficialTimes) {
      await results.upsert(
        id,
        RaceResultInput(
          officialStart: manualStart,
          officialFinish: manualStart.add(const Duration(hours: 3)),
        ),
        updatedAt: now,
      );
    }
  }

  group('PolarRaceCatalog', () {
    test('lists a finished telemetry race with its recording window', () async {
      // ARRANGE: 2026-07-26 11:00 UTC, ket ora
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));

      // ACT
      final race = (await catalog.all()).single;

      // ASSERT
      expect(race.source, PolarSampleSource.telemetry);
      expect(
        race.expectedWindow,
        RecordingWindow(
          TimeWindow(
            start: archiveStart,
            end: archiveStart.add(const Duration(hours: 2)),
          ),
        ),
      );
      expect(race.day, CalendarDate.tryParse('2026-07-26'));
      expect(race.startInstant, archiveStart);
      expect(race.elapsed, const Duration(hours: 2));
    });

    test('uses the official window and time of a telemetry race', () async {
      // ARRANGE
      await seedArchiveRace(databases.archive, finishedArchiveRace('r1'));
      final officialStart = archiveStart.add(const Duration(minutes: 10));
      final officialFinish = officialStart.add(const Duration(minutes: 90));
      await results.upsert(
        'r1',
        RaceResultInput(
          officialStart: officialStart,
          officialFinish: officialFinish,
        ),
        updatedAt: now,
      );

      // ACT
      final race = (await catalog.all()).single;

      // ASSERT
      expect(
        race.expectedWindow,
        OfficialWindow(TimeWindow(start: officialStart, end: officialFinish)),
      );
      expect(race.startInstant, officialStart);
      expect(race.elapsed, const Duration(minutes: 90));
    });

    test('takes the Budapest day of a race after local midnight', () async {
      // ARRANGE: 22:30 UTC = masnap 00:30 Budapesten (nyari ido)
      await seedArchiveRace(
        databases.archive,
        finishedArchiveRace(
          'night',
          offset: const Duration(hours: 11, minutes: 30),
        ),
      );

      // ACT
      final race = (await catalog.all()).single;

      // ASSERT
      expect(race.day, CalendarDate.tryParse('2026-07-27'));
    });

    test('lists a manual race with a track and official times', () async {
      // ARRANGE
      await addManualRace('m1', hasTrack: true, hasOfficialTimes: true);

      // ACT
      final race = await catalog.byId('m1');

      // ASSERT
      expect(race?.source, PolarSampleSource.legacyTrack);
      expect(race?.day, manualDay);
      expect(race?.elapsed, const Duration(hours: 3));
      expect(race?.expectedWindow, isA<OfficialWindow>());
    });

    test('leaves out a manual race without track or official times', () async {
      // ARRANGE
      await addManualRace('no-track', hasTrack: false, hasOfficialTimes: true);
      await addManualRace('no-times', hasTrack: true, hasOfficialTimes: false);

      // ACT + ASSERT
      expect(await catalog.all(), isEmpty);
      expect(await catalog.byId('no-track'), isNull);
    });
  });
}
