import 'package:flutter_test/flutter_test.dart';
import 'package:watch/screens/confidence_haptic_edge.dart';

void main() {
  group('isRisingToHighConfidence', () {
    test('low → high felfutó él → igaz', () {
      expect(isRisingToHighConfidence('low', 'high'), isTrue);
    });

    test('medium → high felfutó él → igaz', () {
      expect(isRisingToHighConfidence('medium', 'high'), isTrue);
    });

    test('null → high (induló high) → igaz', () {
      expect(isRisingToHighConfidence(null, 'high'), isTrue);
    });

    test('high → high (marad) → hamis', () {
      expect(isRisingToHighConfidence('high', 'high'), isFalse);
    });

    test('high → medium (high alá esik) → hamis', () {
      expect(isRisingToHighConfidence('high', 'medium'), isFalse);
    });

    test('medium → low (nincs high) → hamis', () {
      expect(isRisingToHighConfidence('medium', 'low'), isFalse);
    });

    test('high → null (predikció elveszett) → hamis', () {
      expect(isRisingToHighConfidence('high', null), isFalse);
    });
  });
}
