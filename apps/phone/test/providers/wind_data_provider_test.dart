import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/nmea_stream_provider.dart';
import 'package:phone/providers/wind_data_provider.dart';

void main() {
  final clock = DateTime.utc(2026, 5, 28, 10);

  late _FakeNmeaStream fake;
  late ProviderContainer container;

  setUp(() {
    fake = _FakeNmeaStream();
    container = ProviderContainer(
      overrides: [nmeaStreamProvider.overrideWithValue(fake)],
    )..listen(windDataProvider, (_, _) {});
    addTearDown(fake.dispose);
    addTearDown(container.dispose);
  });

  WindData windData({Bearing? twd}) => WindData(
    apparentAngle: const Angle(degrees: 30),
    apparentSpeed: const Speed(metersPerSecond: 4),
    timestamp: clock,
    trueDirectionGround: twd,
  );

  group('windDataProvider', () {
    test('kezdőértéke null', () {
      expect(container.read(windDataProvider), isNull);
    });

    test('WindEvent → a hordozott WindData', () async {
      final data = windData();
      fake.emit(WindEvent(data));
      await pumpEventQueue();

      expect(container.read(windDataProvider), equals(data));
    });

    test('a legfrissebb WindEvent nyer', () async {
      final older = windData();
      final newer = WindData(
        apparentAngle: const Angle(degrees: 45),
        apparentSpeed: const Speed(metersPerSecond: 6),
        timestamp: clock.add(const Duration(seconds: 1)),
      );
      fake
        ..emit(WindEvent(older))
        ..emit(WindEvent(newer));
      await pumpEventQueue();

      expect(container.read(windDataProvider), equals(newer));
    });

    test('nem-szél eseményt figyelmen kívül hagy', () async {
      fake.emit(
        PositionEvent(const Coordinate(latitude: 46, longitude: 17), clock),
      );
      await pumpEventQueue();

      expect(container.read(windDataProvider), isNull);
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
