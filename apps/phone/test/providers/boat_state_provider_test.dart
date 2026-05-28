import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/boat_state_provider.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);
  final gpsInstant = DateTime.utc(2026, 5, 28, 8, 36, 45);

  late _FakeNmeaStream fake;
  late ProviderContainer container;

  setUp(() {
    fake = _FakeNmeaStream();
    // A cascade-listen életben tartja az autoDispose providert és lefuttatja a
    // build()-et (feliratkozás) MIELŐTT a broadcast streamre emittálnánk (az
    // nem pufferel).
    container = ProviderContainer(
      overrides: [
        nmeaStreamProvider.overrideWithValue(fake),
        clockProvider.overrideWithValue(() => clock),
      ],
    )..listen(boatStateProvider, (_, _) {});
    addTearDown(fake.dispose);
    addTearDown(container.dispose);
  });

  Future<void> emit(DomainEvent event) async {
    fake.emit(event);
    await pumpEventQueue();
  }

  group('boatStateProvider', () {
    test('kezdőállapot: csupa-null mező, lastUpdate az órából', () {
      final state = container.read(boatStateProvider);
      expect(state.position, isNull);
      expect(state.lastUpdate, equals(clock));
    });

    test('PositionEvent → position, lastUpdate az órából', () async {
      const position = Coordinate(latitude: 46.9, longitude: 17.9);
      await emit(PositionEvent(position, gpsInstant));

      final state = container.read(boatStateProvider);
      expect(state.position, equals(position));
      // A lastUpdate a receipt-óra, NEM az esemény időbélyege.
      expect(state.lastUpdate, equals(clock));
    });

    test('magneticNorth HeadingEvent → headingMagnetic', () async {
      const heading = Bearing(
        degrees: 120,
        reference: BearingReference.magneticNorth,
      );
      await emit(HeadingEvent(heading, clock));

      final state = container.read(boatStateProvider);
      expect(state.headingMagnetic, equals(heading));
      expect(state.headingTrue, isNull);
    });

    test('trueNorth HeadingEvent → headingTrue', () async {
      const heading = Bearing.true_(120);
      await emit(HeadingEvent(heading, clock));

      final state = container.read(boatStateProvider);
      expect(state.headingTrue, equals(heading));
      expect(state.headingMagnetic, isNull);
    });

    test('CogSogEvent → courseOverGround + speedOverGround', () async {
      const cog = Bearing.true_(150);
      const sog = Speed(metersPerSecond: 5);
      await emit(CogSogEvent(cog, sog, clock));

      final state = container.read(boatStateProvider);
      expect(state.courseOverGround, equals(cog));
      expect(state.speedOverGround, equals(sog));
    });

    test('InstrumentTimeEvent → instrumentTimeUtc a GPS-instant, '
        'lastUpdate az óra', () async {
      await emit(InstrumentTimeEvent(gpsInstant));

      final state = container.read(boatStateProvider);
      expect(state.instrumentTimeUtc, equals(gpsInstant));
      expect(state.lastUpdate, equals(clock));
    });

    test('WindEvent nem módosítja a BoatState-et', () async {
      final before = container.read(boatStateProvider);
      await emit(
        WindEvent(
          WindData(
            apparentAngle: const Angle(degrees: 30),
            apparentSpeed: const Speed(metersPerSecond: 4),
            timestamp: clock,
          ),
        ),
      );

      expect(container.read(boatStateProvider), equals(before));
    });
  });
}

class _FakeNmeaStream implements NmeaStream {
  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();

  void emit(DomainEvent event) => _events.add(event);

  @override
  Stream<DomainEvent> get events => _events.stream;

  @override
  Stream<ConnectionStatus> get statusChanges =>
      const Stream<ConnectionStatus>.empty();

  @override
  ConnectionStatus get currentStatus => const Disconnected();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  Future<void> dispose() async => _events.close();
}
