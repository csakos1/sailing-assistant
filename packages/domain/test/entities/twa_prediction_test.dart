import 'package:domain/src/entities/twa_prediction.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/value_objects/angle.dart';
import 'package:test/test.dart';

void main() {
  group('TwaPrediction', () {
    group('construction', () {
      test('valid mezők → olvashatók', () {
        final p = TwaPrediction(
          twa: const Angle(degrees: 40),
          bandDegrees: 7.5,
          confidence: WindShiftConfidence.medium,
        );

        expect(p.twa, equals(const Angle(degrees: 40)));
        expect(p.bandDegrees, equals(7.5));
        expect(p.confidence, equals(WindShiftConfidence.medium));
      });

      test('band = 0 megengedett (perfekt illesztés)', () {
        expect(
          () => TwaPrediction(
            twa: const Angle(degrees: 0),
            bandDegrees: 0,
            confidence: WindShiftConfidence.high,
          ),
          returnsNormally,
        );
      });
    });

    group('invariants', () {
      test('negatív band → AssertionError', () {
        expect(
          () => TwaPrediction(
            twa: const Angle(degrees: 10),
            bandDegrees: -1,
            confidence: WindShiftConfidence.low,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('NaN band → AssertionError', () {
        expect(
          () => TwaPrediction(
            twa: const Angle(degrees: 10),
            bandDegrees: double.nan,
            confidence: WindShiftConfidence.low,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('equality (Equatable)', () {
      TwaPrediction build() => TwaPrediction(
        twa: const Angle(degrees: 40),
        bandDegrees: 5,
        confidence: WindShiftConfidence.high,
      );

      test('azonos mezők → egyenlő', () {
        expect(build(), equals(build()));
        expect(build().hashCode, equals(build().hashCode));
      });

      test('különböző band → nem egyenlő', () {
        final a = build();
        final b = TwaPrediction(
          twa: const Angle(degrees: 40),
          bandDegrees: 9,
          confidence: WindShiftConfidence.high,
        );
        expect(a, isNot(equals(b)));
      });

      test('különböző confidence → nem egyenlő', () {
        final a = build();
        final b = TwaPrediction(
          twa: const Angle(degrees: 40),
          bandDegrees: 5,
          confidence: WindShiftConfidence.medium,
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
