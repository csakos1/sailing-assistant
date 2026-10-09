import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/legacy_row_problem.dart';
import 'package:web_server/src/legacy/legacy_row_rejection.dart';
import 'package:web_server/src/legacy/legacy_two_day_results.dart';
import 'package:web_server/src/legacy/plan_legacy_import.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';
import 'package:web_server/src/web_db/manual_race_record.dart';

const _wholeResult = RaceResultInput(overallPlace: FinishPlace(2));
const _firstDay = RaceResultInput(overallPlace: FinishPlace(19));
const _secondDay = RaceResultInput(overallPlace: FinishPlace(1));

LegacyRace _race(int rowNumber, String date, {bool isTwoDay = false}) {
  final day = CalendarDate.tryParse(date)!;
  return LegacyRace(
    rowNumber: rowNumber,
    name: 'Sor $rowNumber',
    date: day,
    result: _wholeResult,
    manualRace: ManualRaceInput(name: 'Sor $rowNumber', date: day),
    twoDayResults: isTwoDay
        ? const LegacyTwoDayResults(first: _firstDay, second: _secondDay)
        : null,
  );
}

// A rogzites 08:00Z-kor indul: nyaron 10:00 helyi ido, ugyanazon a napon.
TelemetryCandidate _telemetry(String id, String date, {int hour = 8}) =>
    TelemetryCandidate(
      id: id,
      name: 'Telefon $id',
      startedAt: DateTime.parse('${date}T00:00:00Z').add(Duration(hours: hour)),
    );

Result<LegacyRace, LegacyRowRejection> _ok(LegacyRace race) => Ok(race);

String _fixedId(LegacyRace race) => 'manual-${race.rowNumber}';

void main() {
  group('planLegacyImport', () {
    test('matches a row to the single race of its day', () {
      // ARRANGE
      final race = _race(65, '2026-06-20');
      final target = _telemetry('t1', '2026-06-20');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [target],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.items, [
        PlannedResult(
          race: race,
          target: target,
          result: _wholeResult,
          isExplicit: false,
        ),
      ]);
      expect(plan.telemetryOnly, isEmpty);
      expect(plan.matchProblems, isEmpty);
    });

    test('matches by the local day, not the UTC day', () {
      // ARRANGE: 22:30Z on 06-19 is 00:30 local on 06-20
      final race = _race(65, '2026-06-20');
      final target = TelemetryCandidate(
        id: 't1',
        name: 'Ejjeli',
        startedAt: DateTime.utc(2026, 6, 19, 22, 30),
      );

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [target],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.items.single, isA<PlannedResult>());
    });

    test('plans a manual race for a day without telemetry', () {
      // ARRANGE
      final race = _race(3, '2021-05-15');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: const [],
        manualRaces: const [],
        manualIdOf: _fixedId,
      );

      // ASSERT
      expect(plan.items, [PlannedManualRace(race: race, id: 'manual-3')]);
    });

    test('flags another manual race on the same day as a duplicate', () {
      // ARRANGE
      final race = _race(3, '2021-05-15');
      final other = ManualRaceRecord(
        id: 'kezzel',
        input: ManualRaceInput(name: 'Evadnyito', date: race.date),
        createdAt: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10),
      );
      final itself = ManualRaceRecord(
        id: 'manual-3',
        input: race.manualRace,
        createdAt: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10),
      );

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: const [],
        manualRaces: [other, itself],
        manualIdOf: _fixedId,
      );

      // ASSERT: a re-run does not flag the race it created itself
      final item = plan.items.single as PlannedManualRace;
      expect(item.sameDayManualRaces, [other]);
    });

    test('leaves a day with two races to --match', () {
      // ARRANGE
      final race = _race(65, '2026-06-20');
      final morning = _telemetry('t1', '2026-06-20');
      final afternoon = _telemetry('t2', '2026-06-20', hour: 14);

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [morning, afternoon],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.items, [
        AmbiguousRow(
          race: race,
          candidates: [morning, afternoon],
          reason: AmbiguityReason.severalOnDay,
        ),
      ]);
      expect(plan.telemetryOnly, isEmpty);
    });

    test('resolves the ambiguous day with --match', () {
      // ARRANGE
      final race = _race(65, '2026-06-20');
      final morning = _telemetry('t1', '2026-06-20');
      final afternoon = _telemetry('t2', '2026-06-20', hour: 14);

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [morning, afternoon],
        manualRaces: const [],
        explicitMatches: {'t1': 65},
      );

      // ASSERT
      expect(plan.items, [
        PlannedResult(
          race: race,
          target: morning,
          result: _wholeResult,
          isExplicit: true,
        ),
      ]);
      expect(plan.telemetryOnly, [afternoon]);
    });

    test('matches a row to a race on another day with --match', () {
      // ARRANGE: the sheet says 08-08, the recording started on 08-09
      final race = _race(71, '2026-08-08');
      final target = _telemetry('t1', '2026-08-09');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [target],
        manualRaces: const [],
        explicitMatches: {'t1': 71},
      );

      // ASSERT
      expect((plan.items.single as PlannedResult).target, target);
      expect(plan.telemetryOnly, isEmpty);
    });

    test('splits a two-day row onto the races of both days', () {
      // ARRANGE
      final race = _race(64, '2026-06-13', isTwoDay: true);
      final first = _telemetry('t1', '2026-06-13');
      final second = _telemetry('t2', '2026-06-14');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [second, first],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.items, [
        PlannedResult(
          race: race,
          target: first,
          result: _firstDay,
          isExplicit: false,
          splitDay: 1,
        ),
        PlannedResult(
          race: race,
          target: second,
          result: _secondDay,
          isExplicit: false,
          splitDay: 2,
        ),
      ]);
    });

    test('splits a two-day row by start time with two --match', () {
      // ARRANGE
      final race = _race(64, '2026-06-13', isTwoDay: true);
      final first = _telemetry('t1', '2026-06-13');
      final second = _telemetry('t2', '2026-06-14');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [first, second],
        manualRaces: const [],
        explicitMatches: {'t2': 64, 't1': 64},
      );

      // ASSERT
      final days = plan.items.cast<PlannedResult>();
      expect(days.map((item) => (item.target, item.splitDay)), [
        (first, 1),
        (second, 2),
      ]);
      expect(days.every((item) => item.isExplicit), isTrue);
    });

    test('leaves a two-day row with only one day of telemetry to --match', () {
      // ARRANGE
      final race = _race(64, '2026-06-13', isTwoDay: true);
      final first = _telemetry('t1', '2026-06-13');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [first],
        manualRaces: const [],
      );

      // ASSERT
      expect(
        (plan.items.single as AmbiguousRow).reason,
        AmbiguityReason.twoDayMismatch,
      );
    });

    test('blocks two rows that claim the same race', () {
      // ARRANGE: the second day of row 64 is the day of row 65
      final twoDay = _race(64, '2026-06-13', isTwoDay: true);
      final nextDay = _race(65, '2026-06-14');
      final first = _telemetry('t1', '2026-06-13');
      final second = _telemetry('t2', '2026-06-14');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(twoDay), _ok(nextDay)],
        telemetryRaces: [first, second],
        manualRaces: const [],
      );

      // ASSERT
      expect(
        plan.items.map((item) => (item as AmbiguousRow).reason),
        [AmbiguityReason.sharedCandidate, AmbiguityReason.sharedCandidate],
      );
      expect(plan.telemetryOnly, isEmpty);
    });

    test('lists the races without a row, oldest first', () {
      // ARRANGE
      final late = _telemetry('t2', '2026-09-12');
      final early = _telemetry('t1', '2026-08-29');

      // ACT
      final plan = planLegacyImport(
        rows: const [],
        telemetryRaces: [late, early],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.telemetryOnly, [early, late]);
    });

    test('keeps a rejected row in the plan', () {
      // ARRANGE
      const rejection = LegacyRowRejection(
        rowNumber: 9,
        name: 'Hibas',
        problems: [
          LegacyRowProblem(column: 'Rajt', kind: LegacyProblemKind.unreadable),
        ],
      );

      // ACT
      final plan = planLegacyImport(
        rows: const [Err(rejection)],
        telemetryRaces: const [],
        manualRaces: const [],
      );

      // ASSERT
      expect(plan.items, [const RejectedRow(rejection)]);
    });

    test('reports --match problems', () {
      // ARRANGE
      final race = _race(65, '2026-06-20');
      final target = _telemetry('t1', '2026-06-20');
      final other = _telemetry('t2', '2026-06-21');

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [target, other],
        manualRaces: const [],
        explicitMatches: {'missing': 65, 't1': 99, 't2': 65},
      );

      // ASSERT: unknown race, unknown row; t2 alone is a valid match
      expect(plan.matchProblems, hasLength(2));
      expect((plan.items.single as PlannedResult).target, other);
    });

    test('reports two --match on a one-day row', () {
      // ARRANGE
      final race = _race(65, '2026-06-20');
      final first = _telemetry('t1', '2026-06-20');
      final second = _telemetry('t2', '2026-06-20', hour: 14);

      // ACT
      final plan = planLegacyImport(
        rows: [_ok(race)],
        telemetryRaces: [first, second],
        manualRaces: const [],
        explicitMatches: {'t1': 65, 't2': 65},
      );

      // ASSERT
      expect(plan.matchProblems, hasLength(1));
      expect(plan.items.single, isA<AmbiguousRow>());
    });
  });

  group('legacyManualRaceId', () {
    test('is stable for the same day and name', () {
      // ARRANGE
      final race = _race(3, '2021-05-15');

      // ACT & ASSERT
      expect(legacyManualRaceId(race), legacyManualRaceId(race));
      expect(
        legacyManualRaceId(race),
        isNot(legacyManualRaceId(_race(4, '2021-05-15'))),
      );
    });
  });
}
