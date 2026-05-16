import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  // Közös fixtúrák.
  const sampleMark = Mark(
    sequence: 1,
    name: 'Tihany',
    position: Coordinate(latitude: 46.9, longitude: 17.9),
  );
  const sampleBearing = Bearing(
    degrees: 90,
    reference: BearingReference.trueNorth,
  );
  const sampleDistance = Distance(meters: 1200);
  const sampleCorrection = Angle(degrees: 10);
  const sampleTwa = Angle(degrees: 45);
  const sampleEta = Duration(seconds: 600);
  final sampleTimestamp = DateTime.utc(2025, 6, 1, 10);

  group('konstrukció', () {
    test('minden mezővel létrejön', () {
      // ARRANGE & ACT
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.high,
        calculatedAt: sampleTimestamp,
        courseCorrection: sampleCorrection,
        eta: sampleEta,
        predictedTwaAtMark: sampleTwa,
      );

      // ASSERT
      expect(prediction.mark, sampleMark);
      expect(prediction.bearingToMark, sampleBearing);
      expect(prediction.distanceToMark, sampleDistance);
      expect(prediction.etaSource, EtaSource.sog);
      expect(prediction.shiftConfidence, WindShiftConfidence.high);
      expect(prediction.calculatedAt, sampleTimestamp);
      expect(prediction.courseCorrection, sampleCorrection);
      expect(prediction.eta, sampleEta);
      expect(prediction.predictedTwaAtMark, sampleTwa);
    });

    test('csak kötelező mezőkkel: opcionálisak null-ban', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );

      expect(prediction.courseCorrection, isNull);
      expect(prediction.eta, isNull);
      expect(prediction.predictedTwaAtMark, isNull);
    });
  });

  group('Bearing-reference invariáns', () {
    test('bearingToMark magneticNorth-tal → AssertionError', () {
      expect(
        () => MarkPrediction(
          mark: sampleMark,
          bearingToMark: const Bearing(
            degrees: 90,
            reference: BearingReference.magneticNorth,
          ),
          distanceToMark: sampleDistance,
          etaSource: EtaSource.unknown,
          shiftConfidence: WindShiftConfidence.low,
          calculatedAt: sampleTimestamp,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ETA invariáns assertek', () {
    test('eta != null + etaSource == unknown → AssertionError', () {
      expect(
        () => MarkPrediction(
          mark: sampleMark,
          bearingToMark: sampleBearing,
          distanceToMark: sampleDistance,
          etaSource: EtaSource.unknown,
          shiftConfidence: WindShiftConfidence.low,
          calculatedAt: sampleTimestamp,
          eta: sampleEta,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('eta == null + etaSource == sog → AssertionError', () {
      expect(
        () => MarkPrediction(
          mark: sampleMark,
          bearingToMark: sampleBearing,
          distanceToMark: sampleDistance,
          etaSource: EtaSource.sog,
          shiftConfidence: WindShiftConfidence.low,
          calculatedAt: sampleTimestamp,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('eta == null + etaSource == polar → AssertionError', () {
      expect(
        () => MarkPrediction(
          mark: sampleMark,
          bearingToMark: sampleBearing,
          distanceToMark: sampleDistance,
          etaSource: EtaSource.polar,
          shiftConfidence: WindShiftConfidence.low,
          calculatedAt: sampleTimestamp,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('eta != null + etaSource == sog → OK', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
        eta: sampleEta,
      );
      expect(prediction.eta, sampleEta);
      expect(prediction.etaSource, EtaSource.sog);
    });

    test('eta != null + etaSource == polar → OK (v2 forward-compat)', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.polar,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
        eta: sampleEta,
      );
      expect(prediction.etaSource, EtaSource.polar);
    });

    test('eta == null + etaSource == unknown → OK', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      expect(prediction.eta, isNull);
      expect(prediction.etaSource, EtaSource.unknown);
    });
  });

  group('equality (Equatable)', () {
    test('azonos mezők → egyenlő', () {
      final p1 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.high,
        calculatedAt: sampleTimestamp,
        courseCorrection: sampleCorrection,
        eta: sampleEta,
        predictedTwaAtMark: sampleTwa,
      );
      final p2 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.high,
        calculatedAt: sampleTimestamp,
        courseCorrection: sampleCorrection,
        eta: sampleEta,
        predictedTwaAtMark: sampleTwa,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, p2.hashCode);
    });

    test('különböző bearingToMark → nem egyenlő', () {
      final p1 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      final p2 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: const Bearing(
          degrees: 100,
          reference: BearingReference.trueNorth,
        ),
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      expect(p1, isNot(equals(p2)));
    });

    test('null vs non-null courseCorrection → nem egyenlő', () {
      final p1 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      final p2 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
        courseCorrection: sampleCorrection,
      );
      expect(p1, isNot(equals(p2)));
    });

    test('különböző shiftConfidence → nem egyenlő', () {
      final p1 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      final p2 = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.medium,
        calculatedAt: sampleTimestamp,
      );
      expect(p1, isNot(equals(p2)));
    });
  });

  group('copyWith', () {
    test('egy mező változik, többi marad', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.high,
        calculatedAt: sampleTimestamp,
        courseCorrection: sampleCorrection,
        eta: sampleEta,
      );

      final updated = prediction.copyWith(
        shiftConfidence: WindShiftConfidence.medium,
      );

      expect(updated.shiftConfidence, WindShiftConfidence.medium);
      expect(updated.bearingToMark, sampleBearing);
      expect(updated.eta, sampleEta);
      expect(updated.etaSource, EtaSource.sog);
    });

    test('null paraméter nem változtat', () {
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.unknown,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
      );
      final copy = prediction.copyWith();
      expect(copy, equals(prediction));
    });

    test('invariáns-csatolt mező egyoldalú variálása az asserten bukik', () {
      // etaSource sog → unknown váltása, miközben eta marad sampleEta,
      // sérti az `eta == null ↔ etaSource == unknown` invariánst.
      final prediction = MarkPrediction(
        mark: sampleMark,
        bearingToMark: sampleBearing,
        distanceToMark: sampleDistance,
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.low,
        calculatedAt: sampleTimestamp,
        eta: sampleEta,
      );

      expect(
        () => prediction.copyWith(etaSource: EtaSource.unknown),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
