import 'package:test/test.dart';
import 'package:web_server/src/auth/constant_time.dart';

void main() {
  group('constantTimeEquals', () {
    test('accepts equal byte sequences', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals(<int>[], <int>[]), isTrue);
    });

    test('rejects a difference in any position', () {
      expect(constantTimeEquals([9, 2, 3], [1, 2, 3]), isFalse);
      expect(constantTimeEquals([1, 2, 9], [1, 2, 3]), isFalse);
    });

    test('rejects sequences of different length', () {
      expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });
}
