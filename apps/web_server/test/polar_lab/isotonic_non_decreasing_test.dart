import 'package:test/test.dart';
import 'package:web_server/src/polar_lab/isotonic_non_decreasing.dart';

void main() {
  group('isotonicNonDecreasing', () {
    test('keeps a non-decreasing row unchanged', () {
      expect(isotonicNonDecreasing([1, 2, 2, 3], [1, 1, 1, 1]), [1, 2, 2, 3]);
    });

    test('pools a decreasing pair at its weighted mean', () {
      // (5 x 1 + 3 x 3) / 4 = 3.5
      expect(isotonicNonDecreasing([5, 3], [1, 3]), [3.5, 3.5]);
    });

    test('pools backwards as far as needed', () {
      expect(isotonicNonDecreasing([1, 4, 3, 2], [1, 1, 1, 1]), [1, 3, 3, 3]);
    });

    test('skips the empty cells and keeps them empty', () {
      expect(isotonicNonDecreasing([5, null, 3], [1, 99, 1]), [4, null, 4]);
    });

    test('rejects a non-positive weight of a value', () {
      expect(() => isotonicNonDecreasing([5], [0]), throwsArgumentError);
      expect(() => isotonicNonDecreasing([5], [1, 1]), throwsArgumentError);
    });
  });
}
