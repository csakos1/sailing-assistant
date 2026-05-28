import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TelemetryRecord', () {
    final sampleTime = DateTime(2025, 6, 1, 12);
    const sampleSentence = r'$IIMWV,045.0,R,12.3,N,A*28';

    group('construction', () {
      test('érvényes paraméterekkel létrejön', () {
        final record = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );

        expect(record.raceId, equals('race-1'));
        expect(record.timestamp, equals(sampleTime));
        expect(record.rawSentence, equals(sampleSentence));
      });

      test('üres raceId -> AssertionError', () {
        expect(
          () => TelemetryRecord(
            raceId: '',
            timestamp: sampleTime,
            rawSentence: sampleSentence,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('üres rawSentence -> AssertionError', () {
        expect(
          () => TelemetryRecord(
            raceId: 'race-1',
            timestamp: sampleTime,
            rawSentence: '',
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality', () {
      test('két azonos értékű rekord egyenlő', () {
        final a = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );
        final b = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('különböző timestamp -> nem egyenlő', () {
        final a = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );
        final b = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime.add(const Duration(seconds: 1)),
          rawSentence: sampleSentence,
        );

        expect(a, isNot(equals(b)));
      });

      test('különböző rawSentence -> nem egyenlő', () {
        final a = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );
        final b = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: r'$IIVHW,,,089.0,M,05.2,N,,*4C',
        );

        expect(a, isNot(equals(b)));
      });
    });

    group('toString', () {
      test('tartalmazza a típusnevet és a raceId-t', () {
        final record = TelemetryRecord(
          raceId: 'race-1',
          timestamp: sampleTime,
          rawSentence: sampleSentence,
        );

        final s = record.toString();
        expect(s, contains('TelemetryRecord'));
        expect(s, contains('race-1'));
      });
    });
  });
}
