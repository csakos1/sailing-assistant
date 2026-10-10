import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const position = Coordinate(latitude: 46.95, longitude: 17.90);

  group('StartPoint', () {
    test('equal by name and position', () {
      // Arrange
      const a = StartPoint(name: 'Rajtvonal', position: position);
      const b = StartPoint(name: 'Rajtvonal', position: position);

      // Assert
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('a different name or position differs', () {
      // Arrange
      const base = StartPoint(name: 'Rajtvonal', position: position);
      const renamed = StartPoint(name: 'Masik', position: position);
      const moved = StartPoint(
        name: 'Rajtvonal',
        position: Coordinate(latitude: 46.96, longitude: 17.90),
      );

      // Assert
      expect(renamed, isNot(equals(base)));
      expect(moved, isNot(equals(base)));
    });

    test('an empty name is a programming error', () {
      expect(
        () => StartPoint(name: '', position: position),
        throwsA(isA<AssertionError>()),
      );
    });

    test('becomes a valid guidance mark with its name and position', () {
      // Arrange
      const point = StartPoint(name: 'Rajtvonal', position: position);

      // Act
      final mark = point.asGuidanceMark();

      // Assert: a valid Mark (sequence >= 1), never rounded.
      expect(mark.sequence, StartPoint.guidanceMarkSequence);
      expect(mark.sequence, greaterThanOrEqualTo(1));
      expect(mark.name, 'Rajtvonal');
      expect(mark.position, position);
      expect(mark.roundedAt, isNull);
    });
  });
}
