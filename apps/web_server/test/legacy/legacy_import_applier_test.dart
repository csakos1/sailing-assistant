import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_import_applier.dart';
import 'package:web_server/src/legacy/legacy_import_plan.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/web_db/manual_race_repository.dart';
import 'package:web_server/src/web_db/race_result_repository.dart';

import '../support/archive_fixture.dart';

const _excelResult = RaceResultInput(
  overallPlace: FinishPlace(2),
  overallFleetSize: 58,
  ysNumberHundredths: 7590,
  prize: 'kupa',
);

LegacyRace _race(int rowNumber, {RaceResultInput result = _excelResult}) {
  final day = CalendarDate.tryParse('2026-07-18')!;
  return LegacyRace(
    rowNumber: rowNumber,
    name: 'BAHART Regatta',
    date: day,
    result: result,
    manualRace: ManualRaceInput(
      name: 'BAHART Regatta',
      date: day,
      distanceMeters: 19000,
    ),
  );
}

final _target = TelemetryCandidate(
  id: 't1',
  name: 'BAHART Foldvar',
  startedAt: DateTime.utc(2026, 7, 18, 8),
);

LegacyImportPlan _plan(List<LegacyPlanItem> items) => LegacyImportPlan(
  items: items,
  telemetryOnly: const [],
  matchProblems: const [],
);

void main() {
  late ArchiveDatabases databases;
  late ManualRaceRepository manualRaces;
  late RaceResultRepository results;
  late List<String> refreshed;
  late LegacyImportApplier apply;

  final now = DateTime.utc(2026, 10, 2, 20);

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    databases = await ArchiveDatabases.open();
    manualRaces = ManualRaceRepository(databases.web);
    results = RaceResultRepository(databases.web);
    refreshed = [];
    apply = LegacyImportApplier(
      manualRaces: manualRaces,
      results: results,
      runInTransaction: databases.web.transaction,
      refreshStats: (raceId) async => refreshed.add(raceId),
      now: () => now,
    );
  });

  tearDown(() => databases.close());

  PlannedResult plannedResult({RaceResultInput result = _excelResult}) =>
      PlannedResult(
        race: _race(67, result: result),
        target: _target,
        result: result,
        isExplicit: false,
      );

  PlannedManualRace plannedManualRace() =>
      PlannedManualRace(race: _race(3), id: 'legacy-3');

  group('LegacyImportApplier', () {
    test('writes the result of a matched race and refreshes it', () async {
      // ACT
      final report = await apply(
        _plan([plannedResult()]),
        shouldOverwrite: false,
      );

      // ASSERT
      expect((await results.get('t1'))?.content, _excelResult);
      expect(report.writtenResults, hasLength(1));
      expect(refreshed, ['t1']);
    });

    test('keeps a result entered on the web without --overwrite', () async {
      // ARRANGE
      const entered = RaceResultInput(overallPlace: FinishPlace(1));
      await results.upsert('t1', entered, updatedAt: now);

      // ACT
      final report = await apply(
        _plan([plannedResult()]),
        shouldOverwrite: false,
      );

      // ASSERT
      expect((await results.get('t1'))?.content, entered);
      expect(report.skippedResults, hasLength(1));
      expect(refreshed, isEmpty);
    });

    test('replaces an existing result with --overwrite', () async {
      // ARRANGE
      await results.upsert(
        't1',
        const RaceResultInput(overallPlace: FinishPlace(1)),
        updatedAt: now,
      );

      // ACT
      await apply(_plan([plannedResult()]), shouldOverwrite: true);

      // ASSERT
      expect((await results.get('t1'))?.content, _excelResult);
    });

    test('writes nothing for a row without result data', () async {
      // ACT
      final report = await apply(
        _plan([plannedResult(result: const RaceResultInput())]),
        shouldOverwrite: true,
      );

      // ASSERT
      expect(await results.get('t1'), isNull);
      expect(report.emptyResults, hasLength(1));
      expect(refreshed, isEmpty);
    });

    test('creates a manual race with its result', () async {
      // ACT
      final report = await apply(
        _plan([plannedManualRace()]),
        shouldOverwrite: false,
      );

      // ASSERT
      final record = await manualRaces.get('legacy-3');
      expect(record?.input, _race(3).manualRace);
      expect((await results.get('legacy-3'))?.content, _excelResult);
      expect(report.createdManualRaces, hasLength(1));
    });

    test('does not duplicate or overwrite a manual race on a re-run', () async {
      // ARRANGE: the race was renamed on the web after the first import
      await apply(_plan([plannedManualRace()]), shouldOverwrite: false);
      final renamed = ManualRaceInput(
        name: 'Javitott nev',
        date: _race(3).date,
      );
      await manualRaces.update('legacy-3', renamed, now: now);

      // ACT
      final report = await apply(
        _plan([plannedManualRace()]),
        shouldOverwrite: false,
      );

      // ASSERT
      expect(await manualRaces.getAll(), hasLength(1));
      expect((await manualRaces.get('legacy-3'))?.input, renamed);
      expect(report.skippedManualRaces, hasLength(1));
    });

    test('overwrites a manual race with --overwrite', () async {
      // ARRANGE
      await apply(_plan([plannedManualRace()]), shouldOverwrite: false);
      await manualRaces.update(
        'legacy-3',
        ManualRaceInput(name: 'Javitott nev', date: _race(3).date),
        now: now,
      );

      // ACT
      final report = await apply(
        _plan([plannedManualRace()]),
        shouldOverwrite: true,
      );

      // ASSERT
      expect(
        (await manualRaces.get('legacy-3'))?.input,
        _race(3).manualRace,
      );
      expect(report.overwrittenManualRaces, hasLength(1));
    });

    test('writes nothing for ambiguous rows', () async {
      // ARRANGE
      final ambiguous = AmbiguousRow(
        race: _race(65),
        candidates: [_target],
        reason: AmbiguityReason.severalOnDay,
      );

      // ACT
      await apply(_plan([ambiguous]), shouldOverwrite: true);

      // ASSERT
      expect(await results.getAll(), isEmpty);
      expect(await manualRaces.getAll(), isEmpty);
    });

    test('refuses a plan with --match problems', () async {
      // ARRANGE
      final plan = LegacyImportPlan(
        items: [plannedResult()],
        telemetryOnly: const [],
        matchProblems: const ['--match x: nincs ilyen befejezett verseny'],
      );

      // ACT & ASSERT
      await expectLater(
        apply(plan, shouldOverwrite: false),
        throwsArgumentError,
      );
      expect(await results.getAll(), isEmpty);
    });
  });
}
