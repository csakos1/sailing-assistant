import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('race_codec', () {
    const markA = Mark(
      sequence: 1,
      name: '1. bója',
      position: Coordinate(latitude: 46.9, longitude: 17.9),
    );
    const markB = Mark(
      sequence: 2,
      name: '2. bója',
      position: Coordinate(latitude: 46.8, longitude: 17.8),
    );
    // UTC: a round-trip epoch-millis UTC-instantot ad vissza, így a Race
    // egyenlőség (DateTime == isUtc-érzékeny) tisztán teljesül.
    final startTime = DateTime.utc(2025, 6, 1, 12);
    final finishTime = DateTime.utc(2025, 6, 1, 13);

    test('notStarted Race round-trip', () {
      final race = Race.create(
        id: 'r1',
        name: 'Teszt',
        marks: const [markA, markB],
      );

      final restored = raceFromJson(raceToJson(race));

      expect(restored, equals(race));
    });

    test('active Race round-trip — startedAt megőrződik', () {
      final race = Race.create(
        id: 'r1',
        name: 'Teszt',
        marks: const [markA, markB],
      ).start(at: startTime);

      final restored = raceFromJson(raceToJson(race));

      expect(restored, equals(race));
      expect(restored.status, RaceStatus.active);
      expect(restored.startedAt, startTime);
    });

    test('finished Race round-trip — index == marks.length, finishedAt', () {
      final race = Race.create(
        id: 'r1',
        name: 'Teszt',
        marks: const [markA],
      ).start(at: startTime).roundCurrentMark(at: finishTime);

      final restored = raceFromJson(raceToJson(race));

      expect(restored, equals(race));
      expect(restored.status, RaceStatus.finished);
      expect(restored.finishedAt, finishTime);
      expect(restored.activeMarkIndex, race.marks.length);
    });

    test('a Mark.roundedAt átkel a round-tripen', () {
      final race = Race.create(
        id: 'r1',
        name: 'Teszt',
        marks: const [markA, markB],
      ).start(at: startTime).roundCurrentMark(at: finishTime);

      final restored = raceFromJson(raceToJson(race));

      expect(restored.marks.first.roundedAt, finishTime);
      expect(restored.marks[1].roundedAt, isNull);
    });

    test('a DateTime UTC-instantként jön vissza', () {
      final race = Race.create(
        id: 'r1',
        name: 'Teszt',
        marks: const [markA],
      ).start(at: startTime);

      final restored = raceFromJson(raceToJson(race));

      expect(restored.startedAt!.isUtc, isTrue);
      expect(
        restored.startedAt!.millisecondsSinceEpoch,
        startTime.millisecondsSinceEpoch,
      );
    });
  });
}
