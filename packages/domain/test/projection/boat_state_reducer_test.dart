import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const reducer = BoatStateReducer();

  // Közös fixtúrák.
  const position = Coordinate(latitude: 46.9, longitude: 18.05);
  const headingMag = Bearing(
    degrees: 100,
    reference: BearingReference.magneticNorth,
  );
  const headingTrue = Bearing(
    degrees: 105,
    reference: BearingReference.trueNorth,
  );
  const cog = Bearing(degrees: 110, reference: BearingReference.trueNorth);
  const sog = Speed(metersPerSecond: 3);
  const stw = Speed(metersPerSecond: 2.5);
  const depth = Depth(meters: 2.4);

  // A recept-idő (now) tudatosan eltér az esemény saját időbélyegétől, hogy a
  // lastUpdate=now vs. instrumentTimeUtc=event.timestamp szétválás
  // bizonyítható legyen.
  final eventTime = DateTime.utc(2025, 6, 1, 10);
  final receiptTime = DateTime.utc(2025, 6, 1, 10, 0, 5);
  final seedTime = DateTime.utc(2025, 6, 1, 9);
  final initial = BoatState(lastUpdate: seedTime);

  group('egyetlen esemény foldolása', () {
    test('PositionEvent beállítja a pozíciót, lastUpdate = now', () {
      final result = reducer(
        initial,
        PositionEvent(position, eventTime),
        receiptTime,
      );
      expect(result.position, position);
      expect(result.lastUpdate, receiptTime);
    });

    test('HeadingEvent (magnetic) a headingMagnetic mezőbe kerül', () {
      final result = reducer(
        initial,
        HeadingEvent(headingMag, eventTime),
        receiptTime,
      );
      expect(result.headingMagnetic, headingMag);
      expect(result.headingTrue, isNull);
      expect(result.lastUpdate, receiptTime);
    });

    test('HeadingEvent (true) a headingTrue mezőbe kerül', () {
      final result = reducer(
        initial,
        HeadingEvent(headingTrue, eventTime),
        receiptTime,
      );
      expect(result.headingTrue, headingTrue);
      expect(result.headingMagnetic, isNull);
    });

    test('CogSogEvent beállítja a COG-ot és a SOG-ot', () {
      final result = reducer(
        initial,
        CogSogEvent(cog, sog, eventTime),
        receiptTime,
      );
      expect(result.courseOverGround, cog);
      expect(result.speedOverGround, sog);
      expect(result.lastUpdate, receiptTime);
    });

    test('SpeedEvent beállítja a vízsebességet', () {
      final result = reducer(initial, SpeedEvent(stw, eventTime), receiptTime);
      expect(result.speedThroughWater, stw);
      expect(result.lastUpdate, receiptTime);
    });

    test('DepthEvent beállítja a mélységet', () {
      final result = reducer(
        initial,
        DepthEvent(depth, eventTime),
        receiptTime,
      );
      expect(result.depth, depth);
      expect(result.lastUpdate, receiptTime);
    });

    test(
      'InstrumentTimeEvent: instrumentTimeUtc = esemény-idő, lastUpdate = now',
      () {
        // eventTime a GPS-instant, receiptTime az app-óra; a kettő külön.
        final result = reducer(
          initial,
          InstrumentTimeEvent(eventTime),
          receiptTime,
        );
        expect(result.instrumentTimeUtc, eventTime);
        expect(result.lastUpdate, receiptTime);
      },
    );

    test('WindEvent no-op: az állapot változatlan, lastUpdate sem frissül', () {
      final windData = WindData(
        apparentAngle: const Angle(degrees: 30),
        apparentSpeed: const Speed(metersPerSecond: 5),
        timestamp: eventTime,
      );
      final result = reducer(initial, WindEvent(windData), receiptTime);
      expect(result, initial);
      expect(result.lastUpdate, seedTime);
    });
  });

  group('esemény-szekvencia akkumulálása', () {
    test('több esemény foldolása megőrzi a korábbi mezőket', () {
      var state = initial;
      state = reducer(state, PositionEvent(position, eventTime), receiptTime);
      state = reducer(state, HeadingEvent(headingMag, eventTime), receiptTime);
      state = reducer(state, CogSogEvent(cog, sog, eventTime), receiptTime);

      expect(state.position, position);
      expect(state.headingMagnetic, headingMag);
      expect(state.courseOverGround, cog);
      expect(state.speedOverGround, sog);
    });

    test('a magnetic és a true heading egyszerre, külön mezőben él meg', () {
      var state = initial;
      state = reducer(state, HeadingEvent(headingMag, eventTime), receiptTime);
      state = reducer(state, HeadingEvent(headingTrue, eventTime), receiptTime);

      expect(state.headingMagnetic, headingMag);
      expect(state.headingTrue, headingTrue);
    });
  });
}
