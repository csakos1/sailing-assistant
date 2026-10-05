import 'package:race_archive_api/race_archive_api.dart';
import 'package:test/test.dart';
import 'package:web_server/src/legacy/describe_legacy_import.dart';
import 'package:web_server/src/legacy/legacy_import_plan.dart';
import 'package:web_server/src/legacy/legacy_plan_item.dart';
import 'package:web_server/src/legacy/legacy_race.dart';
import 'package:web_server/src/legacy/telemetry_candidate.dart';

void main() {
  group('describeLegacyPlan', () {
    test('shows what each matched day would receive', () {
      // ARRANGE
      final day = CalendarDate.tryParse('2026-06-13')!;
      final race = LegacyRace(
        rowNumber: 64,
        name: 'Mihálkovics Emlékverseny',
        date: day,
        result: const RaceResultInput(),
        manualRace: ManualRaceInput(name: 'Mihálkovics', date: day),
      );
      final plan = LegacyImportPlan(
        items: [
          PlannedResult(
            race: race,
            target: TelemetryCandidate(
              id: 't2',
              name: 'Mihalkovics 2. nap',
              startedAt: DateTime.utc(2026, 6, 14, 8),
            ),
            result: RaceResultInput(
              classPlace: const FinishPlace(1),
              overallPlace: const FinishPlace(1),
              overallFleetSize: 181,
              ysNumberHundredths: 7590,
              officialStart: DateTime.utc(2026, 6, 14, 8),
            ),
            isExplicit: false,
            splitDay: 2,
          ),
        ],
        telemetryOnly: const [],
        matchProblems: const [],
      );

      // ACT
      final lines = describeLegacyPlan(plan);

      // ASSERT
      expect(lines, contains('Telemetriás versenyhez párosítva: 1'));
      expect(
        lines,
        contains(
          '  64. sor 2026-06-13 Mihálkovics Emlékverseny · 2. nap',
        ),
      );
      expect(
        lines,
        contains(
          '    → 2026-06-14 10:00:00 Mihalkovics 2. nap [t2]',
        ),
      );
      expect(
        lines,
        contains(
          '    eredmény: oszt. 1. · absz. 1./181 · YS 75,90 · '
          'rajt 2026-06-14 10:00:00',
        ),
      );
    });

    test('marks a race that already has a result', () {
      // ARRANGE
      final day = CalendarDate.tryParse('2026-07-18')!;
      final plan = LegacyImportPlan(
        items: [
          PlannedResult(
            race: LegacyRace(
              rowNumber: 67,
              name: 'BAHART',
              date: day,
              result: const RaceResultInput(),
              manualRace: ManualRaceInput(name: 'BAHART', date: day),
            ),
            target: TelemetryCandidate(
              id: 't1',
              name: 'Foldvar',
              startedAt: DateTime.utc(2026, 7, 18, 9),
            ),
            result: const RaceResultInput(overallPlace: FinishPlace(2)),
            isExplicit: false,
          ),
        ],
        telemetryOnly: const [],
        matchProblems: const [],
      );

      // ACT
      final lines = describeLegacyPlan(plan, existingResultIds: {'t1'});

      // ASSERT
      expect(
        lines,
        contains('    MÁR VAN EREDMÉNYE: csak --overwrite-tal íródik'),
      );
    });

    test('lists the --match problems only when there are any', () {
      // ARRANGE
      const plan = LegacyImportPlan(
        items: [],
        telemetryOnly: [],
        matchProblems: [],
      );

      // ACT
      final lines = describeLegacyPlan(plan);

      // ASSERT
      expect(lines.any((line) => line.startsWith('--match')), isFalse);
    });
  });
}
