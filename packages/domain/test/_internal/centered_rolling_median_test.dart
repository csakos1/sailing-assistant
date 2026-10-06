import 'package:domain/src/_internal/centered_rolling_median.dart';
import 'package:test/test.dart';

void main() {
  group('centeredRollingMedians', () {
    test('shortens the window at both ends', () {
      // Given: az elso elem ablaka [1, 2, 3], a masodike [1, 2, 3, 4].
      const values = <double>[1, 2, 3, 4, 5];

      // When
      final medians = centeredRollingMedians(values, windowSize: 5);

      // Then
      expect(medians, [2, 2, 3, 3, 4]);
    });

    test('hides a one-sample spike from its own median', () {
      expect(
        centeredRollingMedians(
          const [10, 10, 10, 68, 10, 10, 10],
          windowSize: 5,
        ),
        [10, 10, 10, 10, 10, 10, 10],
      );
    });

    test('follows a three-sample gust', () {
      expect(
        centeredRollingMedians(
          const [10, 10, 25, 25, 25, 10, 10],
          windowSize: 5,
        ),
        [10, 10, 25, 25, 25, 10, 10],
      );
    });

    test('window of one -> the values themselves', () {
      expect(centeredRollingMedians(const [3, 1, 2], windowSize: 1), [3, 1, 2]);
    });

    test('empty input -> empty list', () {
      expect(centeredRollingMedians(const [], windowSize: 5), isEmpty);
    });

    test('rejects an even or non-positive window', () {
      expect(
        () => centeredRollingMedians(const [1], windowSize: 4),
        throwsArgumentError,
      );
      expect(
        () => centeredRollingMedians(const [1], windowSize: 0),
        throwsArgumentError,
      );
    });
  });
}
