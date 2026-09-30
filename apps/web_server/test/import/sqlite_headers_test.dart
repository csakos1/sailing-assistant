import 'dart:convert';

import 'package:test/test.dart';
import 'package:web_server/src/import/sqlite_headers.dart';

void main() {
  group('hasSqliteHeader', () {
    test('accepts the SQLite format 3 magic', () {
      final header = [...ascii.encode('SQLite format 3'), 0, 1, 2];

      expect(hasSqliteHeader(header), isTrue);
    });

    test('rejects text and short input', () {
      expect(hasSqliteHeader(utf8.encode('cat: no such file')), isFalse);
      expect(hasSqliteHeader(ascii.encode('SQLite')), isFalse);
    });
  });

  group('classifyWalHeader', () {
    List<int> walHeader(int lastMagicByte) => [
      0x37,
      0x7f,
      0x06,
      lastMagicByte,
      ...List<int>.filled(28, 0),
    ];

    test('treats a zero-length file as empty', () {
      expect(classifyWalHeader(const [], fileLength: 0), WalHeaderKind.empty);
    });

    test('accepts both WAL magic variants', () {
      expect(
        classifyWalHeader(walHeader(0x82), fileLength: 32),
        WalHeaderKind.valid,
      );
      expect(
        classifyWalHeader(walHeader(0x83), fileLength: 4128),
        WalHeaderKind.valid,
      );
    });

    test('rejects an adb error message saved as the WAL', () {
      final text = utf8.encode(
        'cat: app_flutter/foretack.sqlite-wal: No such file or directory\n',
      );

      expect(
        classifyWalHeader(text.take(32).toList(), fileLength: text.length),
        WalHeaderKind.invalid,
      );
    });

    test('rejects a non-empty file shorter than the WAL header', () {
      expect(
        classifyWalHeader(walHeader(0x82).take(8).toList(), fileLength: 8),
        WalHeaderKind.invalid,
      );
    });
  });
}
