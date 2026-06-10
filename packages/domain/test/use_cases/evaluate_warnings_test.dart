import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final lastUpdate = DateTime.utc(2025, 6, 1, 10);
  const position = Coordinate(latitude: 46.9, longitude: 17.9);
  final boatWithFix = BoatState(lastUpdate: lastUpdate, position: position);
  final boatNoFix = BoatState(lastUpdate: lastUpdate);
  final sampleTrend = WindShiftTrend(
    shiftRateDegPerMinute: 2,
    currentTwd: const Bearing.true_(200),
    confidence: WindShiftConfidence.high,
    sampleCount: 15,
    windowDuration: const Duration(minutes: 10),
    residualStdErrorDeg: 1,
    slopeStdErrorDegPerMin: 0.1,
    meanSampleTime: lastUpdate,
  );

  // Alap: csatlakozott, van fix, nincs trend, nincs verseny → tiszta
  // (üres) eredmény, amihez tesztenként egy-egy inputot billentünk át.
  List<Warning> evaluate({
    ConnectionStatus connectionStatus = const Connected(),
    BoatState? boatState,
    WindShiftTrend? windShiftTrend,
    RaceStatus raceStatus = RaceStatus.notStarted,
    bool isTimeUnsynced = false,
    Duration? timeStreamDrift,
    EvaluateWarnings useCase = const EvaluateWarnings(),
  }) {
    return useCase(
      connectionStatus: connectionStatus,
      boatState: boatState ?? boatWithFix,
      windShiftTrend: windShiftTrend,
      raceStatus: raceStatus,
      isTimeUnsynced: isTimeUnsynced,
      timeStreamDrift: timeStreamDrift,
    );
  }

  group('EvaluateWarnings', () {
    group('gateway gating', () {
      test('nem csatlakozott → csak GatewayDisconnected', () {
        // Minden downstream feltétel teljesül, mégis egyetlen jelzés.
        final result = evaluate(
          connectionStatus: const Disconnected(),
          boatState: boatNoFix,
          isTimeUnsynced: true,
          raceStatus: RaceStatus.active,
        );

        expect(result, [const GatewayDisconnected()]);
      });

      test('Connecting → csak GatewayDisconnected', () {
        expect(
          evaluate(connectionStatus: const Connecting()),
          [const GatewayDisconnected()],
        );
      });

      test('ConnectionError → csak GatewayDisconnected', () {
        expect(
          evaluate(connectionStatus: const ConnectionError('timeout')),
          [const GatewayDisconnected()],
        );
      });

      test('csatlakozott, minden rendben → üres lista', () {
        expect(evaluate(), isEmpty);
      });
    });

    group('GpsSignalLost', () {
      test('csatlakozott, nincs pozíció → tartalmazza', () {
        expect(
          evaluate(boatState: boatNoFix),
          contains(const GpsSignalLost()),
        );
      });

      test('csatlakozott, van pozíció → nem tartalmazza', () {
        expect(
          evaluate(boatState: boatWithFix),
          isNot(contains(const GpsSignalLost())),
        );
      });
    });

    group('GpsTimeUnsynced', () {
      test('isTimeUnsynced=true → tartalmazza, drifttől függetlenül', () {
        expect(
          evaluate(isTimeUnsynced: true),
          contains(const GpsTimeUnsynced()),
        );
      });

      test('nincs jelzés és nincs drift → nem tartalmazza', () {
        expect(evaluate(), isNot(contains(const GpsTimeUnsynced())));
      });

      test('drift a küszöb alatt (5 < 10 mp) → nem tartalmazza', () {
        expect(
          evaluate(timeStreamDrift: const Duration(seconds: 5)),
          isNot(contains(const GpsTimeUnsynced())),
        );
      });

      test('drift pontosan a küszöbön (10 mp) → nem (szigorú >)', () {
        expect(
          evaluate(timeStreamDrift: const Duration(seconds: 10)),
          isNot(contains(const GpsTimeUnsynced())),
        );
      });

      test('drift a küszöb fölött (11 mp) → tartalmazza', () {
        expect(
          evaluate(timeStreamDrift: const Duration(seconds: 11)),
          contains(const GpsTimeUnsynced()),
        );
      });

      test('negatív drift abszolút értéke a küszöb fölött → tartalmazza', () {
        // A jel iránya nem számít: a chartplotter elé VAGY mögé csúszott
        // idő egyaránt szinkronhiány.
        expect(
          evaluate(timeStreamDrift: const Duration(seconds: -12)),
          contains(const GpsTimeUnsynced()),
        );
      });

      test('egyedi küszöb (3 mp): 5 mp drift → tartalmazza', () {
        expect(
          evaluate(
            useCase: const EvaluateWarnings(
              timeDriftThreshold: Duration(seconds: 3),
            ),
            timeStreamDrift: const Duration(seconds: 5),
          ),
          contains(const GpsTimeUnsynced()),
        );
      });
    });

    group('WindShiftTrendInsufficient', () {
      test('trend null + status active → tartalmazza', () {
        expect(
          evaluate(raceStatus: RaceStatus.active),
          contains(const WindShiftTrendInsufficient()),
        );
      });

      test('trend null + status notStarted → nem (rajt előtt normális)', () {
        // A helper alapértelmezett raceStatus-a notStarted (rajt előtt).
        expect(
          evaluate(),
          isNot(contains(const WindShiftTrendInsufficient())),
        );
      });

      test('trend null + status finished → nem tartalmazza', () {
        expect(
          evaluate(raceStatus: RaceStatus.finished),
          isNot(contains(const WindShiftTrendInsufficient())),
        );
      });

      test('van trend + status active → nem tartalmazza', () {
        expect(
          evaluate(windShiftTrend: sampleTrend, raceStatus: RaceStatus.active),
          isNot(contains(const WindShiftTrendInsufficient())),
        );
      });
    });

    group('sorrend és halmozódás', () {
      test('mindhárom downstream aktív → fix prioritási sorrend', () {
        // Csatlakozott, nincs fix, idő-szinkronhiány, aktív versenyben
        // nincs trend → mindhárom, severity-csökkenő sorrendben.
        final result = evaluate(
          boatState: boatNoFix,
          isTimeUnsynced: true,
          raceStatus: RaceStatus.active,
        );

        expect(result, [
          const GpsSignalLost(),
          const GpsTimeUnsynced(),
          const WindShiftTrendInsufficient(),
        ]);
      });
    });

    group('SuspectHeadingWarning', () {
      // Heading és COG egyaránt trueNorth (ADR 0013); a küszöb 35°, 2.0 kn.
      BoatState boatHeadingCog({
        required double headingDeg,
        required double cogDeg,
        required double sogMps,
      }) {
        return BoatState(
          lastUpdate: lastUpdate,
          position: position,
          headingTrue: Bearing.true_(headingDeg),
          courseOverGround: Bearing.true_(cogDeg),
          speedOverGround: Speed(metersPerSecond: sogMps),
        );
      }

      test('SOG és eltérés is a küszöb fölött → tartalmazza', () {
        // 60° eltérés, ~3 kn (1.54 m/s) → mindkét feltétel teljesül.
        final result = evaluate(
          boatState: boatHeadingCog(headingDeg: 100, cogDeg: 160, sogMps: 1.54),
        );

        expect(result, contains(const SuspectHeadingWarning()));
      });

      test('SOG a küszöb alatt → nem tartalmazza', () {
        // ~1 kn (0.51 m/s) a 2.0 kn kapu alatt → nincs riasztás.
        final result = evaluate(
          boatState: boatHeadingCog(headingDeg: 100, cogDeg: 160, sogMps: 0.51),
        );

        expect(result, isNot(contains(const SuspectHeadingWarning())));
      });

      test('eltérés a küszöb alatt → nem tartalmazza', () {
        // 10° eltérés bőven a 35° alatt, hiába gyors a hajó.
        final result = evaluate(
          boatState: boatHeadingCog(headingDeg: 100, cogDeg: 110, sogMps: 3),
        );

        expect(result, isNot(contains(const SuspectHeadingWarning())));
      });

      test('pontosan a küszöbön (35°, 2.0 kn) → tartalmazza (>=)', () {
        // Inkluzív küszöb: a pont-küszöbnyi eset is riaszt.
        final result = evaluate(
          boatState: boatHeadingCog(
            headingDeg: 100,
            cogDeg: 135,
            sogMps: 1.0289,
          ),
        );

        expect(result, contains(const SuspectHeadingWarning()));
      });

      test('hiányzó heading → nem tartalmazza', () {
        // Heading nélkül nem számolható az eltérés.
        final result = evaluate(
          boatState: BoatState(
            lastUpdate: lastUpdate,
            position: position,
            courseOverGround: const Bearing.true_(160),
            speedOverGround: const Speed(metersPerSecond: 1.54),
          ),
        );

        expect(result, isNot(contains(const SuspectHeadingWarning())));
      });

      test('nem csatlakozott → elnyomva a gating miatt', () {
        // A gateway-gating minden downstream warningot elnyom.
        final result = evaluate(
          connectionStatus: const Disconnected(),
          boatState: boatHeadingCog(headingDeg: 100, cogDeg: 160, sogMps: 1.54),
        );

        expect(result, isNot(contains(const SuspectHeadingWarning())));
      });
    });
  });
}
