import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const isResumable = IsRaceResumable();
  const mark = Mark(
    sequence: 1,
    name: 'A',
    position: Coordinate(latitude: 46.9, longitude: 18),
  );
  final race = Race.create(id: 'race-1', name: 'Teszt', marks: const [mark]);
  final startedAt = DateTime.utc(2026, 7, 30, 7);
  final active = race.start(at: startedAt);

  group('IsRaceResumable', () {
    test('a race started an hour ago without recording resumes', () {
      // Act
      final result = isResumable(
        race: active,
        lastRecordedAt: null,
        now: startedAt.add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isTrue);
    });

    test('a two-day race recording overnight resumes after midnight', () {
      // Arrange: started yesterday morning, recorded a minute ago.
      final now = DateTime.utc(2026, 7, 31, 1);

      // Act
      final result = isResumable(
        race: active,
        lastRecordedAt: now.subtract(const Duration(minutes: 1)),
        now: now,
      );

      // Assert
      expect(result, isTrue);
    });

    test('a forgotten finish does not resume the next day', () {
      // Arrange: the last recording was yesterday afternoon.
      final lastRecordedAt = DateTime.utc(2026, 7, 30, 14);

      // Act
      final result = isResumable(
        race: active,
        lastRecordedAt: lastRecordedAt,
        now: DateTime.utc(2026, 7, 31, 8),
      );

      // Assert
      expect(result, isFalse);
    });

    test('the gap must be shorter than the maximum', () {
      // Arrange
      final lastRecordedAt = startedAt.add(const Duration(hours: 2));

      // Act
      final atLimit = isResumable(
        race: active,
        lastRecordedAt: lastRecordedAt,
        now: lastRecordedAt.add(IsRaceResumable.defaultMaximumGap),
      );
      final justBefore = isResumable(
        race: active,
        lastRecordedAt: lastRecordedAt,
        now: lastRecordedAt
            .add(IsRaceResumable.defaultMaximumGap)
            .subtract(const Duration(seconds: 1)),
      );

      // Assert
      expect(atLimit, isFalse);
      expect(justBefore, isTrue);
    });

    test('a recording older than the start counts the start', () {
      // Act
      final result = isResumable(
        race: active,
        lastRecordedAt: startedAt.subtract(const Duration(days: 2)),
        now: startedAt.add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isTrue);
    });

    test('activity in the future (clock skew) counts as recent', () {
      // Act
      final result = isResumable(
        race: active,
        lastRecordedAt: startedAt.add(const Duration(hours: 1)),
        now: startedAt,
      );

      // Assert
      expect(result, isTrue);
    });

    test('a race not yet started or already finished never resumes', () {
      // Arrange
      final now = startedAt.add(const Duration(minutes: 5));
      final finished = active.finish(at: now);

      // Act / Assert
      expect(isResumable(race: race, lastRecordedAt: now, now: now), isFalse);
      expect(
        isResumable(race: finished, lastRecordedAt: now, now: now),
        isFalse,
      );
    });

    test('a custom maximum gap is honoured', () {
      // Arrange
      const strict = IsRaceResumable(maximumGap: Duration(minutes: 30));

      // Act
      final result = strict(
        race: active,
        lastRecordedAt: startedAt,
        now: startedAt.add(const Duration(hours: 1)),
      );

      // Assert
      expect(result, isFalse);
    });
  });
}
