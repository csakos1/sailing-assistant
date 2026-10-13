import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/archive_copies.dart';

void main() {
  late Directory root;
  late Directory workDir;
  late File archive;
  late File webDb;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('archive-copies-test');
    workDir = await Directory('${root.path}/work').create();
    // Az ures fajl ervenyes, ures SQLite-adatbazis.
    archive = await File('${root.path}/archive.sqlite').create();
    webDb = await File('${root.path}/web.sqlite').create();
  });

  tearDown(() => root.delete(recursive: true));

  Future<T> run<T>(
    Future<T> Function(ArchiveCopies copies) body, {
    List<String>? log,
  }) => withArchiveCopies(
    archivePath: archive.path,
    webDbPath: webDb.path,
    workDirPath: workDir.path,
    tempPrefix: 'copies-',
    log: (line) => log?.add(line),
    body: body,
  );

  group('withArchiveCopies', () {
    test('runs the body on copies in a temporary directory', () async {
      final log = <String>[];
      List<String>? namesDuringBody;

      final result = await run((copies) async {
        namesDuringBody = [
          for (final entity in workDir.listSync(recursive: true))
            entity.path.split('/').last,
        ];
        return 42;
      }, log: log);

      expect(result, 42);
      expect(
        namesDuringBody,
        containsAll(<String>['archive.sqlite', 'web.sqlite']),
      );
      expect(log.single, startsWith('Másolás: ${workDir.path}/copies-'));
    });

    test('deletes the copies afterwards and keeps the originals', () async {
      await run<void>((copies) async {});

      expect(workDir.listSync(), isEmpty);
      expect(archive.existsSync(), isTrue);
      expect(webDb.existsSync(), isTrue);
    });

    test('deletes the copies when the body fails', () async {
      await expectLater(
        run<void>((copies) async => throw StateError('hiba')),
        throwsStateError,
      );

      expect(workDir.listSync(), isEmpty);
    });
  });
}
