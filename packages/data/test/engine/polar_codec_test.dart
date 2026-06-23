import 'package:data/src/engine/polar_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('polarToJson / polarFromJson', () {
    test('round-trips a polar with real cells and empty buckets', () {
      // Arrange — minta-polár két TWS-oszloppal és egy üres vödörrel.
      final polar = Polar(
        twaAxis: const [0, 40, 90],
        twsAxis: const [4, 8],
        grid: const [
          [null, null], // no-go: mindkét cella üres
          [4.1, 5.6],
          [5.0, 6.4],
        ],
      );

      // Act
      final restored = polarFromJson(polarToJson(polar));

      // Assert
      expect(restored, polar);
    });

    test('preserves null buckets distinctly from zero speeds', () {
      // Arrange
      final polar = Polar(
        twaAxis: const [30, 60],
        twsAxis: const [6],
        grid: const [
          [null],
          [0],
        ],
      );

      // Act
      final restored = polarFromJson(polarToJson(polar));

      // Assert — a null vödör null marad, a 0.0 sebesség 0.0.
      expect(restored.grid[0][0], isNull);
      expect(restored.grid[1][0], 0.0);
    });
  });
}
