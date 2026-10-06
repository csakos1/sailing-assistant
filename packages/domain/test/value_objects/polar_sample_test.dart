import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PolarSample', () {
    test('normalizes the timestamp to UTC', () {
      // Given: ugyanaz a pillanat +02:00 zonaban
      final local = DateTime.parse('2026-07-26T12:00:00+02:00');

      // When
      final sample = PolarSample(timestamp: local);

      // Then
      expect(sample.timestamp, DateTime.utc(2026, 7, 26, 10));
      expect(sample.timestamp.isUtc, isTrue);
    });

    test('weighs one second by default', () {
      expect(PolarSample(timestamp: DateTime.utc(2026)).durationSeconds, 1);
    });

    test('compares by value', () {
      PolarSample sample() => PolarSample(
        timestamp: DateTime.utc(2026, 7, 26, 10),
        twaDeg: -42,
        twsMps: 5,
        stwMps: 3,
        durationSeconds: 10,
      );

      expect(sample(), sample());
    });
  });
}
