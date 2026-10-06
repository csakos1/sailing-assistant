import 'package:test/test.dart';
import 'package:web_server/src/export/export_layout.dart';
import 'package:web_server/src/export/export_readme.dart';

void main() {
  group('exportReadme', () {
    String readme(DateTime exportedAt) => exportReadme(
      exportedAt: exportedAt,
      raceCount: 74,
      serverVersion: '0.1.0',
      archiveSchemaVersion: 5,
      webSchemaVersion: 4,
    );

    test('states the export time in UTC and in Budapest summer time', () {
      final text = readme(DateTime.utc(2026, 10, 6, 9, 30));

      expect(text, contains('2026-10-06 09:30:00 UTC'));
      expect(text, contains('2026-10-06 11:30:00 (Budapest)'));
    });

    test('uses the winter offset after the October switch', () {
      final text = readme(DateTime.utc(2026, 11, 2, 9, 30));

      expect(text, contains('2026-11-02 10:30:00 (Budapest)'));
    });

    test('names the files, the versions and the race count', () {
      final text = readme(DateTime.utc(2026, 10, 6, 9, 30));

      expect(text, contains('Versenyek:     74'));
      expect(text, contains('web_server 0.1.0'));
      expect(text, contains('sémaverzió: 5'));
      expect(text, contains('sémaverzió: 4'));
      expect(text, contains('format: foretack-history, version: 1'));
      for (final name in [
        exportArchiveFileName,
        exportWebDatabaseFileName,
        exportHistoryJsonFileName,
        exportReadmeFileName,
      ]) {
        expect(text, contains(name));
      }
    });
  });

  group('exportBaseName', () {
    test('uses the Budapest day of the export', () {
      expect(
        exportBaseName(DateTime.utc(2026, 10, 6, 9, 30)),
        'foretack-history-2026-10-06',
      );
    });

    test('rolls over to the next day before midnight UTC', () {
      // 22:30 UTC nyari idoben mar 00:30 Budapesten.
      expect(
        exportBaseName(DateTime.utc(2026, 10, 6, 22, 30)),
        'foretack-history-2026-10-07',
      );
    });
  });
}
