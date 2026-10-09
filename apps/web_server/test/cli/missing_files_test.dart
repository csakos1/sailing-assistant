import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/cli/missing_files.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('foretack_cli');
  });

  tearDown(() => directory.delete(recursive: true));

  test('reports nothing when every file exists', () {
    // ARRANGE
    final file = File('${directory.path}/web.sqlite')..createSync();

    // ACT
    final lines = missingFileLines({'web-db': file.path});

    // ASSERT
    expect(lines, isEmpty);
  });

  test('reports the missing files in option order', () {
    // ARRANGE
    final existing = File('${directory.path}/web.sqlite')..createSync();
    final missingArchive = '${directory.path}/archive.sqlite';
    final missingCsv = '${directory.path}/polar.csv';

    // ACT
    final lines = missingFileLines({
      'archive': missingArchive,
      'web-db': existing.path,
      'csv': missingCsv,
    });

    // ASSERT
    expect(lines, [
      '--archive: a fájl nem létezik: $missingArchive',
      '--csv: a fájl nem létezik: $missingCsv',
    ]);
  });

  test('treats a directory as missing', () {
    // ACT
    final lines = missingFileLines({'csv': directory.path});

    // ASSERT
    expect(lines, ['--csv: a fájl nem létezik: ${directory.path}']);
  });
}
