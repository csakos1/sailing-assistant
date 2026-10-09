import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:web_server/src/export/export_bundle.dart';

// A csomag streamje egy tobb chunkos fajlon: a takaritas pontosan egyszer
// fut, a stream vegen es a lemondasnal is.

void main() {
  late Directory directory;
  late File file;
  late int releases;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('export_bundle');
    file = File('${directory.path}/export.tar.gz');
    // 2 MiB: a File.openRead 64 KiB-os chunkokban olvas.
    await file.writeAsBytes(List<int>.filled(2 * 1024 * 1024, 7));
    releases = 0;
  });

  tearDown(() => directory.delete(recursive: true));

  ExportBundle bundle() => ExportBundle(
    fileName: 'x.tar.gz',
    length: file.lengthSync(),
    file: file,
    release: () async => releases++,
  );

  test('streams the whole file and releases once at the end', () async {
    var received = 0;
    await bundle().read().forEach((chunk) => received += chunk.length);

    expect(received, 2 * 1024 * 1024);
    expect(releases, 1);
  });

  test('releases when cancelled in the middle', () async {
    final firstChunk = Completer<void>();
    final subscription = bundle().read().listen((_) {
      if (!firstChunk.isCompleted) firstChunk.complete();
    });

    await firstChunk.future;
    await subscription.cancel();

    expect(releases, 1);
  });

  test('releases when cancelled before the first chunk', () async {
    final subscription = bundle().read().listen((_) {});

    await subscription.cancel();

    expect(releases, 1);
  });

  test('releases and reports a read error', () async {
    final missing = ExportBundle(
      fileName: 'x.tar.gz',
      length: 0,
      file: File('${directory.path}/missing.tar.gz'),
      release: () async => releases++,
    );

    await expectLater(
      missing.read().drain<void>(),
      throwsA(isA<FileSystemException>()),
    );
    expect(releases, 1);
  });
}
