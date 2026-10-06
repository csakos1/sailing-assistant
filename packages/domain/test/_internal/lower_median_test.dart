import 'package:domain/src/_internal/lower_median.dart';
import 'package:test/test.dart';

void main() {
  group('lowerMedian', () {
    test('odd count -> the middle value', () {
      expect(lowerMedian(const [3, 1, 2]), 2);
    });

    test('even count -> the lower middle value', () {
      expect(lowerMedian(const [4, 1, 3, 2]), 2);
    });

    test('leaves the input in its order', () {
      // Given
      final values = [3.0, 1.0, 2.0];

      // When
      lowerMedian(values);

      // Then
      expect(values, [3.0, 1.0, 2.0]);
    });
  });
}
