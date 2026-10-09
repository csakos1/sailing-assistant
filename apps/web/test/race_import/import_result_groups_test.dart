import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foretack_web/race_import/import_result_groups.dart';
import 'package:race_archive_api/race_archive_api.dart';

void main() {
  ImportedRace race(String name, DateTime finishedAt) =>
      ImportedRace(id: name, name: name, finishedAt: finishedAt);

  group('importResultGroupsOf', () {
    test('orders the groups as added, updated, skipped', () {
      // ARRANGE
      final report = ImportReport(
        added: [race('Evadzaro', DateTime.utc(2026, 9, 26))],
        updated: [race('Beszedes', DateTime.utc(2026, 9, 5))],
        skipped: const [
          SkippedRace(id: 's', name: 'Tihanyi', status: RaceStatus.active),
        ],
        warnings: const [],
      );

      // ACT
      final groups = importResultGroupsOf(report);

      // ASSERT
      expect(groups.map((group) => group.kind), [
        ImportResultKind.added,
        ImportResultKind.updated,
        ImportResultKind.skipped,
      ]);
      expect(groups.last.entries.single, (name: 'Tihanyi', finishedAt: null));
    });

    test('puts the newest race first within a group', () {
      // ARRANGE
      final report = ImportReport(
        added: [
          race('Oszi', DateTime.utc(2026, 9, 19)),
          race('Evadzaro', DateTime.utc(2026, 9, 26)),
        ],
        updated: const [],
        skipped: const [],
        warnings: const [],
      );

      // ACT
      final entries = importResultGroupsOf(report).single.entries;

      // ASSERT
      expect(entries.map((entry) => entry.name), ['Evadzaro', 'Oszi']);
    });

    test('leaves out empty groups', () {
      // ARRANGE
      const report = ImportReport(
        added: [],
        updated: [],
        skipped: [],
        warnings: [],
      );

      // ACT + ASSERT
      expect(importResultGroupsOf(report), isEmpty);
    });
  });
}
