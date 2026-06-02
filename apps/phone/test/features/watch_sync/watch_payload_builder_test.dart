import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/app/true_time.dart';
import 'package:phone/features/watch_sync/watch_payload_builder.dart';
import 'package:shared/shared.dart';

void main() {
  group('buildWatchPayload', () {
    final now = DateTime.utc(2026, 6, 2, 10, 30);
    final gpsUtc = DateTime.utc(2026, 6, 2, 10, 29, 58);

    const sog3 = Speed(metersPerSecond: 3); // ≈ 5.8315 csomó
    const mark = Mark(
      sequence: 1,
      name: 'Tihany',
      position: Coordinate(latitude: 46.9, longitude: 17.9),
    );
    const bearing = Bearing(degrees: 90, reference: BearingReference.trueNorth);

    final fullBoat = BoatState(lastUpdate: now, speedOverGround: sog3);
    final fullWind = WindData(
      apparentAngle: const Angle(degrees: 45),
      apparentSpeed: const Speed(metersPerSecond: 7),
      trueAngleWater: const Angle(degrees: 35),
      timestamp: now,
    );
    final fullPrediction = MarkPrediction(
      mark: mark,
      bearingToMark: bearing,
      distanceToMark: const Distance(meters: 1200),
      etaSource: EtaSource.sog,
      shiftConfidence: WindShiftConfidence.high,
      calculatedAt: now,
      courseCorrection: const Angle(degrees: 10),
      eta: const Duration(seconds: 600),
      predictedTwaAtMark: const Angle(degrees: 45),
    );

    // Fake lokalizáló: a codeId-t adja, hogy a tartalom-átvitel ellenőrizhető.
    String localize(Warning warning) => warning.codeId;

    WatchPayload build({
      BoatState? boatState,
      TrueTimeReading? trueTime,
      List<Warning> activeWarnings = const <Warning>[],
      WindData? windData,
      MarkPrediction? prediction,
    }) {
      return buildWatchPayload(
        boatState: boatState ?? BoatState(lastUpdate: now),
        trueTime:
            trueTime ??
            TrueTimeReading(utc: gpsUtc, source: TrueTimeSource.gnss),
        activeWarnings: activeWarnings,
        localizeWarning: localize,
        now: now,
        windData: windData,
        prediction: prediction,
      );
    }

    test('maps all displayed values from full inputs', () {
      // Act
      final payload = build(
        boatState: fullBoat,
        windData: fullWind,
        prediction: fullPrediction,
      );

      // Assert
      expect(payload.timestamp, now);
      expect(payload.gpsTimeUtc, gpsUtc);
      expect(payload.isGpsTimeTrusted, isTrue);
      expect(payload.sogKnots, closeTo(5.831532, 1e-6));
      expect(payload.vmgKnots, isNull);
      expect(payload.currentTwa, 35);
      expect(payload.predictedTwaAtMark, 45);
      expect(payload.courseCorrection, 10);
      expect(payload.etaSeconds, 600);
      expect(payload.distanceMeters, 1200);
      expect(payload.markName, 'Tihany');
      expect(payload.criticalWarnings, isEmpty);
    });

    test('null prediction blanks the mark-derived fields', () {
      // Act — nincs aktív bója, de a szél-eredetű TWA megvan
      final payload = build(windData: fullWind);

      // Assert
      expect(payload.predictedTwaAtMark, isNull);
      expect(payload.courseCorrection, isNull);
      expect(payload.etaSeconds, isNull);
      expect(payload.distanceMeters, isNull);
      expect(payload.markName, isNull);
      expect(payload.currentTwa, 35);
    });

    test('null SOG yields null sogKnots', () {
      // Act
      final payload = build(boatState: BoatState(lastUpdate: now));

      // Assert
      expect(payload.sogKnots, isNull);
    });

    test('keeps only critical warnings, localized and ordered', () {
      // A GpsTimeUnsynced warning-súlyosságú (ADR 0014) → kiesik a szűrőn.
      // Act
      final payload = build(
        activeWarnings: const <Warning>[
          GatewayDisconnected(),
          GpsTimeUnsynced(),
          GpsSignalLost(),
        ],
      );

      // Assert
      expect(
        payload.criticalWarnings,
        equals(<String>['gateway_disconnected', 'gps_signal_lost']),
      );
    });

    for (final (source, trusted) in const <(TrueTimeSource, bool)>[
      (TrueTimeSource.gnss, true),
      (TrueTimeSource.sessionAnchor, true),
      (TrueTimeSource.wallClockUnsynced, false),
      (TrueTimeSource.none, false),
    ]) {
      test('isGpsTimeTrusted is $trusted for $source', () {
        // Act
        final payload = build(
          trueTime: TrueTimeReading(utc: gpsUtc, source: source),
        );

        // Assert
        expect(payload.isGpsTimeTrusted, trusted);
      });
    }
  });
}
