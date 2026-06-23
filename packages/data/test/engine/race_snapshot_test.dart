import 'dart:convert';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RaceSnapshot JSON', () {
    final tickTime = DateTime.utc(2026, 6, 4, 12, 30, 15);
    final boatTime = DateTime.utc(2026, 6, 4, 12, 30, 14);
    final windTime = DateTime.utc(2026, 6, 4, 12, 30, 13);
    final instrumentTime = DateTime.utc(2026, 6, 4, 12, 30, 10);
    final calcTime = DateTime.utc(2026, 6, 4, 12, 30, 15);

    const mark = Mark(
      sequence: 2,
      name: 'Tihany',
      position: Coordinate(latitude: 46.91, longitude: 17.89),
    );

    RaceSnapshot fullSnapshot() => RaceSnapshot(
      eventCount: 142,
      boatState: BoatState(
        lastUpdate: boatTime,
        position: const Coordinate(latitude: 46.9, longitude: 18.05),
        headingMagnetic: const Bearing(
          degrees: 88,
          reference: BearingReference.magneticNorth,
        ),
        headingTrue: const Bearing(
          degrees: 92,
          reference: BearingReference.trueNorth,
        ),
        courseOverGround: const Bearing(
          degrees: 95,
          reference: BearingReference.trueNorth,
        ),
        speedOverGround: const Speed(metersPerSecond: 3.2),
        speedThroughWater: const Speed(metersPerSecond: 3),
        instrumentTimeUtc: instrumentTime,
      ),
      connectionStatus: const Connected(),
      raceStatus: RaceStatus.active,
      tickTime: tickTime,
      wind: WindData(
        apparentAngle: const Angle(degrees: 35),
        apparentSpeed: const Speed(metersPerSecond: 6.5),
        timestamp: windTime,
        trueAngleWater: const Angle(degrees: 40),
        trueSpeedWater: const Speed(metersPerSecond: 5.8),
        trueDirectionGround: const Bearing(
          degrees: 200,
          reference: BearingReference.trueNorth,
        ),
      ),
      prediction: MarkPrediction(
        mark: mark,
        bearingToMark: const Bearing(
          degrees: 110,
          reference: BearingReference.trueNorth,
        ),
        distanceToMark: const Distance(meters: 850),
        etaSource: EtaSource.sog,
        shiftConfidence: WindShiftConfidence.medium,
        calculatedAt: calcTime,
        courseCorrection: const Angle(degrees: 12),
        eta: const Duration(minutes: 4, seconds: 25),
        predictedTwaAtMark: const Angle(degrees: -38),
        forecastBandDegrees: 6.5,
      ),
      windShiftTrend: WindShiftTrend(
        shiftRateDegPerMinute: 1.5,
        currentTwd: const Bearing.true_(200),
        confidence: WindShiftConfidence.medium,
        sampleCount: 18,
        windowDuration: const Duration(minutes: 10),
        residualStdErrorDeg: 1.4,
        slopeStdErrorDegPerMin: 0.35,
        meanSampleTime: calcTime,
      ),
      twdQuality: TwdQuality.held,
      targetSpeedKnots: 6.42,
      vmgKnots: 4.5,
      targetVmgKnots: 5.1,
    );

    test('teljes snapshot round-trip — minden mező megőrződik', () {
      // ARRANGE
      final original = fullSnapshot();

      // ACT
      final restored = RaceSnapshot.fromJson(original.toJson());

      // ASSERT
      expect(restored.eventCount, original.eventCount);
      expect(restored.boatState, original.boatState);
      expect(restored.connectionStatus, isA<Connected>());
      expect(restored.raceStatus, original.raceStatus);
      expect(restored.wind, original.wind);
      expect(restored.prediction, original.prediction);
      expect(restored.windShiftTrend, original.windShiftTrend);
      expect(restored.twdQuality, original.twdQuality);
      expect(restored.tickTime, original.tickTime);
      expect(restored.targetSpeedKnots, original.targetSpeedKnots);
      expect(restored.vmgKnots, original.vmgKnots);
      expect(restored.targetVmgKnots, original.targetVmgKnots);
    });

    test('a twdQuality default + hiányzó kulcs unavailable-re dekódol', () {
      // ARRANGE — minimális snapshot, twdQuality explicit nincs megadva.
      final minimal = RaceSnapshot(
        eventCount: 0,
        boatState: BoatState(lastUpdate: boatTime),
        connectionStatus: const Disconnected(),
        tickTime: tickTime,
      );
      // A toJson-ből kivesszük a kulcsot — régi / forward-kompat payload.
      final json = minimal.toJson()..remove('twdQuality');

      // ACT
      final restored = RaceSnapshot.fromJson(json);

      // ASSERT — a default és a defenzív dekóder is unavailable.
      expect(minimal.twdQuality, TwdQuality.unavailable);
      expect(restored.twdQuality, TwdQuality.unavailable);
    });

    test('valódi jsonEncode/jsonDecode körön át is megőrződik (natív híd)', () {
      // ARRANGE
      final original = fullSnapshot();

      // ACT — egész↔double ingadozás szimulálása a Data Layer JSON-határán
      final wire =
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final restored = RaceSnapshot.fromJson(wire);

      // ASSERT
      expect(restored.boatState, original.boatState);
      expect(restored.wind, original.wind);
      expect(restored.prediction, original.prediction);
      expect(restored.windShiftTrend, original.windShiftTrend);
    });

    test('minimális snapshot — az opcionális mezők null-ok maradnak', () {
      // ARRANGE
      final original = RaceSnapshot(
        eventCount: 0,
        boatState: BoatState(lastUpdate: boatTime),
        connectionStatus: const Disconnected(),
        tickTime: tickTime,
      );

      // ACT
      final restored = RaceSnapshot.fromJson(original.toJson());

      // ASSERT
      expect(restored.wind, isNull);
      expect(restored.prediction, isNull);
      expect(restored.windShiftTrend, isNull);
      expect(restored.boatState.position, isNull);
      expect(restored.boatState.instrumentTimeUtc, isNull);
      expect(restored.connectionStatus, isA<Disconnected>());
    });

    test('a ConnectionStatus minden variánsa round-trip-el', () {
      ConnectionStatus roundTrip(ConnectionStatus s) {
        final snap = RaceSnapshot(
          eventCount: 1,
          boatState: BoatState(lastUpdate: boatTime),
          connectionStatus: s,
          tickTime: tickTime,
        );
        return RaceSnapshot.fromJson(snap.toJson()).connectionStatus;
      }

      expect(roundTrip(const Connected()), isA<Connected>());
      expect(roundTrip(const Connecting()), isA<Connecting>());
      expect(roundTrip(const Disconnected()), isA<Disconnected>());

      final restoredError = roundTrip(
        const ConnectionError('Kapcsolat megszakadt'),
      );
      expect(restoredError, isA<ConnectionError>());
      expect(
        (restoredError as ConnectionError).message,
        'Kapcsolat megszakadt',
      );
    });

    test('lokális DateTime forrásból UTC-instant áll vissza', () {
      // ARRANGE — lokális (nem-UTC) forrás, ugyanazzal az epoch-millisszel
      final localTick = DateTime.fromMillisecondsSinceEpoch(
        tickTime.millisecondsSinceEpoch,
      );
      expect(localTick.isUtc, isFalse);
      final original = RaceSnapshot(
        eventCount: 1,
        boatState: BoatState(lastUpdate: boatTime),
        connectionStatus: const Connected(),
        tickTime: localTick,
      );

      // ACT
      final restored = RaceSnapshot.fromJson(original.toJson());

      // ASSERT
      expect(restored.tickTime.isUtc, isTrue);
      expect(
        restored.tickTime.millisecondsSinceEpoch,
        tickTime.millisecondsSinceEpoch,
      );
    });
  });
}
