import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/nmea_stream_provider.dart';
import 'package:phone/providers/wind_history_provider.dart';

void main() {
  final base = DateTime.utc(2026, 5, 28, 10);

  late _FakeNmeaStream fake;
  late ProviderContainer container;

  setUp(() {
    fake = _FakeNmeaStream();
    container = ProviderContainer(
      overrides: [nmeaStreamProvider.overrideWithValue(fake)],
    )..listen(windHistoryProvider, (_, _) {});
    addTearDown(fake.dispose);
    addTearDown(container.dispose);
  });

  WindEvent windEvent({required DateTime at, Bearing? twd}) => WindEvent(
    WindData(
      apparentAngle: const Angle(degrees: 30),
      apparentSpeed: const Speed(metersPerSecond: 4),
      timestamp: at,
      trueDirectionGround: twd,
    ),
  );

  group('windHistoryProvider', () {
    test('kezdőértéke üres', () {
      expect(container.read(windHistoryProvider), isEmpty);
    });

    test('TWD-vel rendelkező WindEvent → observation a pufferben', () async {
      fake.emit(windEvent(at: base, twd: const Bearing.true_(200)));
      await pumpEventQueue();

      final history = container.read(windHistoryProvider);
      expect(history, hasLength(1));
      expect(history.single.twd, equals(const Bearing.true_(200)));
      expect(history.single.timestamp, equals(base));
    });

    test('TWD nélküli WindEvent → nem fűz observationt', () async {
      fake.emit(windEvent(at: base));
      await pumpEventQueue();

      expect(container.read(windHistoryProvider), isEmpty);
    });

    test('30 percnél régebbi observationt levág', () async {
      // Régi (base), majd 31 perccel későbbi → a régi kiesik a 30 perces
      // ablakból (a legfrissebb observationhöz mérve).
      fake
        ..emit(windEvent(at: base, twd: const Bearing.true_(200)))
        ..emit(
          windEvent(
            at: base.add(const Duration(minutes: 31)),
            twd: const Bearing.true_(210),
          ),
        );
      await pumpEventQueue();

      final history = container.read(windHistoryProvider);
      expect(history, hasLength(1));
      expect(history.single.twd, equals(const Bearing.true_(210)));
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
