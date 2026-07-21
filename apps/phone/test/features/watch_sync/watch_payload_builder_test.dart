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
      forecastBandDegrees: 6.5,
    );

    // Fake lokalizáló: a codeId-t adja, hogy a tartalom-átvitel ellenőrizhető.
    String localize(Warning warning) => warning.codeId;

    WatchPayload build({
      BoatState? boatState,
      TrueTimeReading? trueTime,
      List<Warning> activeWarnings = const <Warning>[],
      WindData? windData,
      MarkPrediction? prediction,
      TwdQuality twdQuality = TwdQuality.unavailable,
      double? targetSpeedKnots,
      double? vmgSteerCorrection,
      double? depthAlertMeters,
      int depthBuzzCounter = 0,
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
        twdQuality: twdQuality,
        targetSpeedKnots: targetSpeedKnots,
        vmgSteerCorrection: vmgSteerCorrection,
        depthAlertMeters: depthAlertMeters,
        depthBuzzCounter: depthBuzzCounter,
      );
    }

    test('maps all displayed values from full inputs', () {
      // Act
      final payload = build(
        boatState: fullBoat,
        windData: fullWind,
        prediction: fullPrediction,
        twdQuality: TwdQuality.live,
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
      expect(payload.twdQuality, 'live');
      expect(payload.shiftConfidence, 'high');
      expect(payload.forecastBandDegrees, 6.5);
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
      expect(payload.shiftConfidence, isNull);
      expect(payload.currentTwa, 35);
    });

    test('null SOG yields null sogKnots', () {
      // Act
      final payload = build(boatState: BoatState(lastUpdate: now));

      // Assert
      expect(payload.sogKnots, isNull);
    });

    test('passes the VMG steer correction through to the payload', () {
      // Act
      final withSteer = build(vmgSteerCorrection: -8.5);
      final withoutSteer = build();

      // Assert
      expect(withSteer.vmgSteerCorrection, -8.5);
      expect(withoutSteer.vmgSteerCorrection, isNull);
    });

    test('passes the depth alert fields through to the payload', () {
      // A mélység-riasztást a builder NEM származtatja: ha a hívó (a
      // task handler) elfelejti átadni, a default csendben 0/null marad,
      // és az óra sosem rezegne (ADR 0031 D4). Ezért a defaultot is
      // rögzítjük, nem csak az átvitelt.
      // Act
      final alerting = build(depthAlertMeters: 2.4, depthBuzzCounter: 3);
      final quiet = build();

      // Assert
      expect(alerting.depthAlertMeters, 2.4);
      expect(alerting.depthBuzzCounter, 3);
      expect(quiet.depthAlertMeters, isNull);
      expect(quiet.depthBuzzCounter, 0);
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

    test('twdQuality defaults to unavailable when not supplied', () {
      // Act
      final payload = build();

      // Assert
      expect(payload.twdQuality, 'unavailable');
    });

    test('twdQuality maps through to its enum name', () {
      // Act
      final payload = build(twdQuality: TwdQuality.held);

      // Assert
      expect(payload.twdQuality, 'held');
    });

    test('payloads differing only in twdQuality are not equal', () {
      // A change-detect alapja: a hero-opacitás váltásához (live→
      // held) is új DataItemet kell küldeni, ezért a twdQuality
      // bekerül a props-ba.
      // Act
      final live = build(twdQuality: TwdQuality.live);
      final held = build(twdQuality: TwdQuality.held);

      // Assert
      expect(live, isNot(equals(held)));
    });

    test('a cél-sebesség %-a az STW-ből és a célból számol', () {
      // ARRANGE — STW 3 m/s (= 5.831532 kn), cél 7 kn.
      const stw = Speed(metersPerSecond: 3);
      final boat = BoatState(lastUpdate: now, speedThroughWater: stw);

      // ACT
      final payload = build(boatState: boat, targetSpeedKnots: 7);

      // ASSERT — 5.831532 / 7 * 100.
      expect(payload.targetSpeedPercent, closeTo(83.3076, 1e-3));
    });

    test('cél nélkül vagy sebesség nélkül a % null', () {
      // ARRANGE / ACT — van STW, de nincs cél.
      const stw = Speed(metersPerSecond: 3);
      final boat = BoatState(lastUpdate: now, speedThroughWater: stw);
      final noTarget = build(boatState: boat);
      // Van cél, de nincs sebesség.
      final noSpeed = build(
        boatState: BoatState(lastUpdate: now),
        targetSpeedKnots: 7,
      );

      // ASSERT
      expect(noTarget.targetSpeedPercent, isNull);
      expect(noSpeed.targetSpeedPercent, isNull);
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
