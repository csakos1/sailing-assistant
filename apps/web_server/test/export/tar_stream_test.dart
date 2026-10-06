import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web_server/src/export/tar_entry.dart';
import 'package:web_server/src/export/tar_stream.dart';
import 'package:web_server/src/export/ustar_header.dart';

// A tar-stream szerkezete blokkokra bontva; a fejlec-bajtokat az
// ustar_header_test ellenorzi, itt a sorrend, a kiegeszites es a zaras.

final DateTime _modified = DateTime.utc(2026, 10, 6, 9, 30);

Future<Uint8List> _collect(Stream<List<int>> stream) async {
  final builder = BytesBuilder(copy: false);
  await stream.forEach(builder.add);
  return builder.takeBytes();
}

String _nameAt(Uint8List archive, int offset) =>
    ascii.decode(archive.sublist(offset, offset + 100)).replaceAll('\x00', '');

void main() {
  group('tarStream', () {
    test('ends an empty archive with two zero blocks', () async {
      final archive = await _collect(tarStream([], modified: _modified));

      expect(archive, Uint8List(2 * tarBlockSize));
    });

    test('pads the content to a whole block', () async {
      final archive = await _collect(
        tarStream([
          TarEntry.bytes(name: 'a.txt', bytes: utf8.encode('hello')),
        ], modified: _modified),
      );

      expect(archive, hasLength(4 * tarBlockSize));
      expect(_nameAt(archive, 0), 'a.txt');
      expect(utf8.decode(archive.sublist(512, 517)), 'hello');
      expect(archive.sublist(517), everyElement(0));
    });

    test('adds no padding to content of a whole block', () async {
      final archive = await _collect(
        tarStream([
          TarEntry.bytes(name: 'a', bytes: List<int>.filled(512, 7)),
          TarEntry.bytes(name: 'b', bytes: const []),
        ], modified: _modified),
      );

      // a fejlece, a tartalma, b fejlece (ures tartalom), ket zaro blokk
      expect(archive, hasLength(5 * tarBlockSize));
      expect(_nameAt(archive, 2 * tarBlockSize), 'b');
    });

    test('streams the entries in order with their mtime', () async {
      final archive = await _collect(
        tarStream([
          TarEntry.bytes(name: 'first', bytes: const [1]),
          TarEntry.bytes(name: 'second', bytes: const [2]),
        ], modified: _modified),
      );

      expect(_nameAt(archive, 0), 'first');
      expect(_nameAt(archive, 2 * tarBlockSize), 'second');
      expect(
        archive.sublist(2 * tarBlockSize, 3 * tarBlockSize),
        ustarHeader(name: 'second', size: 1, modified: _modified),
      );
    });

    test('concatenates a source delivered in several chunks', () async {
      final archive = await _collect(
        tarStream([
          TarEntry(
            name: 'chunked',
            size: 6,
            open: () => Stream.fromIterable([
              [1, 2],
              [3, 4, 5],
              [6],
            ]),
          ),
        ], modified: _modified),
      );

      expect(archive.sublist(512, 518), [1, 2, 3, 4, 5, 6]);
    });

    test('fails when a source is shorter than its size', () async {
      final stream = tarStream([
        TarEntry(name: 'short', size: 3, open: () => Stream.value([1])),
      ], modified: _modified);

      await expectLater(_collect(stream), throwsStateError);
    });

    test('fails when a source is longer than its size', () async {
      final stream = tarStream([
        TarEntry(name: 'long', size: 1, open: () => Stream.value([1, 2])),
      ], modified: _modified);

      await expectLater(_collect(stream), throwsStateError);
    });

    test('reads a file entry with its current length', () async {
      final directory = await Directory.systemTemp.createTemp('tar_entry');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/data.bin');
      await file.writeAsBytes(List<int>.filled(700, 9));

      final entry = await TarEntry.file(name: 'data.bin', file: file);
      final archive = await _collect(tarStream([entry], modified: _modified));

      expect(entry.size, 700);
      expect(archive.sublist(512, 1212), everyElement(9));
      expect(archive, hasLength(5 * tarBlockSize));
    });
  });
}
