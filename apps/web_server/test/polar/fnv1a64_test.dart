import 'dart:convert';

import 'package:test/test.dart';
import 'package:web_server/src/polar/fnv1a64.dart';

void main() {
  group('fnv1a64Hex', () {
    test('matches the published test vectors', () {
      expect(fnv1a64Hex(const []), 'cbf29ce484222325');
      expect(fnv1a64Hex(utf8.encode('a')), 'af63dc4c8601ec8c');
      expect(fnv1a64Hex(utf8.encode('foobar')), '85944171f73967e8');
    });

    test('always gives sixteen hex digits', () {
      expect(fnv1a64Hex(utf8.encode('Lola')), matches(r'^[0-9a-f]{16}$'));
    });
  });
}
