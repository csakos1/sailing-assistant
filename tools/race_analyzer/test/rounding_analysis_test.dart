import 'dart:io';

import 'package:domain/domain.dart';
import 'package:race_analyzer/race_analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('fixtura (2026-06-06 bootstrap)', () {
    test('a valodi snapshot_logs ket korozest ad, lancba fuzve', () {
      final fixture = File('test/fixtures/snapshot_logs_2026_06_06.jsonl');
      if (!fixture.existsSync()) {
        markTestSkipped('nincs fixtura — futtasd a bootstrapot (ADR 0025 D5)');
        return;
      }

      // ACT — a tool olvasoja + a domain use case egyutt (pipeline).
      final snaps = readSnapshotsFromJsonl(fixture.path);
      final results = const AnalyzeRoundings()(snaps);

      // ASSERT — szerkezet (a konkret ertekeket a CLI-report mutatja).
      expect(snaps, isNotEmpty);
      expect(results, hasLength(2), reason: 'VK->BS es BS->VK2');
      expect(results[0].toMark, results[1].fromMark); // a kozepso boja
      expect(results[0].roundedAt.isBefore(results[1].roundedAt), isTrue);
    });
  });
}
