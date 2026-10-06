import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/export/stale_export_cleanup.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('stale_export');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('removes only the export directories', () async {
    final stale = await Directory('${root.path}/foretack-export-abc').create();
    await File('${stale.path}/x.tar.gz').writeAsString('x');
    await Directory('${root.path}/foretack-import-abc').create();
    await File('${root.path}/foretack-export-file').writeAsString('x');

    final removed = await removeStaleExportDirectories(root);

    expect(removed, 1);
    expect(stale.existsSync(), isFalse);
    expect(Directory('${root.path}/foretack-import-abc').existsSync(), isTrue);
    expect(File('${root.path}/foretack-export-file').existsSync(), isTrue);
  });

  test('accepts a missing temp root', () async {
    await root.delete(recursive: true);

    expect(await removeStaleExportDirectories(root), 0);
  });
}
