import 'package:domain/src/entities/boat_state.dart';
import 'package:domain/src/entities/eta_source.dart';
import 'package:domain/src/entities/mark.dart';
import 'package:domain/src/entities/wind_shift_confidence.dart';
import 'package:domain/src/entities/wind_shift_trend.dart';
import 'package:domain/src/use_cases/compute_mark_prediction.dart';
import 'package:domain/src/value_objects/bearing.dart';
import 'package:domain/src/value_objects/coordinate.dart';
import 'package:domain/src/value_objects/speed.dart';
import 'package:test/test.dart';

void main() {
  const boatPosition = Coordinate(latitude: 46, longitude: 17);
  // A bója pontosan a hajótól északra (Δlon = 0) → a Haversine-távolság
  // R·Δlat, a bearing pedig pontosan 0° true.
  const mark = Mark(
    sequence: 1,
    name: '1. bója',
    position: Coordinate(latitude: 46.01, longitude: 17),
  );
  final now = DateTime.utc(2026, 5, 25, 12);
  final trend = WindShiftTrend(
    shiftRateDegPerMinute: 2,
    currentTwd: const Bearing.true_(200),
    confidence: WindShiftConfidence.high,
    sampleCount: 15,
    windowDuration: const Duration(minutes: 10),
  );
  const sut = ComputeMarkPrediction();

  group('ComputeMarkPrediction', () {
    test('null-t ad, ha nincs aktív bója', () {
      final boatState = BoatState(lastUpdate: now, position: boatPosition);

      final result = sut(
        activeMark: null,
        boatState: boatState,
        trend: trend,
        now: now,
      );

      expect(result, isNull);
    });

    test('null-t ad, ha nincs hajó-pozíció', () {
      final boatState = BoatState(lastUpdate: now);

      final result = sut(
        activeMark: mark,
        boatState: boatState,
        trend: trend,
        now: now,
      );

      expect(result, isNull);
    });

    test('teljes happy path — minden mező kitöltve, helyes wiring', () {
      final boatState = BoatState(
        lastUpdate: now,
        position: boatPosition,
        courseOverGround: const Bearing.true_(90),
        speedOverGround: const Speed(metersPerSecond: 5),
      );

      final result = sut(
        activeMark: mark,
        boatState: boatState,
        trend: trend,
        now: now,
      );

      expect(result, isNotNull);
      final p = result!;
      expect(p.mark, mark);
      // 0° bizonyítja a from→to sorrendet (fordítva 180° lenne).
      expect(p.bearingToMark.reference, BearingReference.trueNorth);
      expect(p.bearingToMark.degrees, closeTo(0, 0.001));
      expect(p.distanceToMark.meters, closeTo(1112, 5));
      expect(p.courseCorrection, isNotNull);
      expect(p.eta, isNotNull);
      expect(p.etaSource, EtaSource.sog);
      expect(p.predictedTwaAtMark, isNotNull);
      expect(p.shiftConfidence, WindShiftConfidence.high);
      expect(p.calculatedAt, now);
    });

    test('trend nélkül a predicted TWA null és a confidence low', () {
      final boatState = BoatState(
        lastUpdate: now,
        position: boatPosition,
        courseOverGround: const Bearing.true_(90),
        speedOverGround: const Speed(metersPerSecond: 5),
      );

      final result = sut(
        activeMark: mark,
        boatState: boatState,
        trend: null,
        now: now,
      );

      expect(result, isNotNull);
      final p = result!;
      expect(p.predictedTwaAtMark, isNull);
      expect(p.shiftConfidence, WindShiftConfidence.low);
    });

    test('SOG nélkül az ETA null és az etaSource unknown', () {
      // headingTrue marad effektív iránynak, hogy az ETA-t izoláljuk.
      final boatState = BoatState(
        lastUpdate: now,
        position: boatPosition,
        headingTrue: const Bearing.true_(45),
      );

      final result = sut(
        activeMark: mark,
        boatState: boatState,
        trend: trend,
        now: now,
      );

      expect(result, isNotNull);
      final p = result!;
      expect(p.eta, isNull);
      expect(p.etaSource, EtaSource.unknown);
    });

    test('effektív irány nélkül a courseCorrection null', () {
      // Van SOG (ETA-hoz), de sem COG, sem headingTrue → effektív irány
      // null, miközben az ETA számolódik.
      final boatState = BoatState(
        lastUpdate: now,
        position: boatPosition,
        speedOverGround: const Speed(metersPerSecond: 3),
      );

      final result = sut(
        activeMark: mark,
        boatState: boatState,
        trend: trend,
        now: now,
      );

      expect(result, isNotNull);
      final p = result!;
      expect(p.courseCorrection, isNull);
      expect(p.eta, isNotNull);
    });
  });
}
