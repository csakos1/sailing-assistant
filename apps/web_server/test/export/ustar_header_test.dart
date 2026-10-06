import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:web_server/src/export/ustar_header.dart';

// A varhato bajtokat a POSIX ustar formatum mezoi adjak (offset, hossz);
// a checksum kezzel ujraszamolva.

String _field(Uint8List header, int offset, int length) =>
    ascii.decode(header.sublist(offset, offset + length));

void main() {
  final modified = DateTime.utc(2026, 10, 6, 9, 30);

  group('ustarHeader', () {
    test('is exactly one block', () {
      final header = ustarHeader(name: 'a', size: 0, modified: modified);

      expect(header, hasLength(tarBlockSize));
    });

    test('writes the name NUL-padded at the start', () {
      final header = ustarHeader(
        name: 'foretack-history-2026-10-06/README.txt',
        size: 5,
        modified: modified,
      );

      expect(
        _field(header, 0, 100),
        'foretack-history-2026-10-06/README.txt'.padRight(100, '\x00'),
      );
    });

    test('writes mode, owner, size and mtime as octal', () {
      final header = ustarHeader(name: 'a', size: 1536, modified: modified);

      expect(_field(header, 100, 8), '0000644\x00');
      expect(_field(header, 108, 8), '0000000\x00');
      expect(_field(header, 116, 8), '0000000\x00');
      // 1536 = 0o3000
      expect(_field(header, 124, 12), '00000003000\x00');
      // 2026-10-06 09:30 UTC = 1791279000 s = 0o15261137630
      expect(_field(header, 136, 12), '15261137630\x00');
    });

    test('marks a regular ustar file', () {
      final header = ustarHeader(name: 'a', size: 0, modified: modified);

      expect(header[156], 0x30);
      expect(_field(header, 257, 6), 'ustar\x00');
      expect(_field(header, 263, 2), '00');
    });

    test('stores the sum of the bytes with the checksum field as spaces', () {
      final header = ustarHeader(name: 'a', size: 0, modified: modified);
      final stored = int.parse(_field(header, 148, 6), radix: 8);
      final recomputed = [
        ...header.sublist(0, 148),
        ...List<int>.filled(8, 0x20),
        ...header.sublist(156),
      ].fold<int>(0, (sum, byte) => sum + byte);

      expect(stored, recomputed);
      expect(header.sublist(154, 156), [0x00, 0x20]);
    });

    test('accepts the largest size the field can hold', () {
      final header = ustarHeader(
        name: 'a',
        size: ustarMaxFileSize,
        modified: modified,
      );

      expect(_field(header, 124, 12), '77777777777\x00');
    });

    test('rejects a size beyond 8 GiB', () {
      expect(
        () => ustarHeader(
          name: 'a',
          size: ustarMaxFileSize + 1,
          modified: modified,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a negative size', () {
      expect(
        () => ustarHeader(name: 'a', size: -1, modified: modified),
        throwsArgumentError,
      );
    });

    test('rejects an empty, a too long and a non-printable name', () {
      for (final name in ['', 'x' * 101, 'árvíz.txt', 'a\tb']) {
        expect(
          () => ustarHeader(name: name, size: 0, modified: modified),
          throwsArgumentError,
          reason: name,
        );
      }
    });

    test('accepts a name of exactly 100 bytes without a terminator', () {
      final header = ustarHeader(name: 'x' * 100, size: 0, modified: modified);

      expect(_field(header, 0, 100), 'x' * 100);
    });

    test('drops the sub-second part of the mtime', () {
      final withMillis = ustarHeader(
        name: 'a',
        size: 0,
        modified: modified.add(const Duration(milliseconds: 999)),
      );

      expect(_field(withMillis, 136, 12), '15261137630\x00');
    });
  });
}
