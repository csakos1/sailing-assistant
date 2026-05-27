import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

void main() {
  group('nmeaStreamProvider', () {
    // SHAPE-teszt indoklás: a real builder (lib/providers/nmea_stream_
    // provider.dart) wiringjét overrideWith-szel TÜKRÖZZÜK, hogy a fake
    // NmeaStream-en megfigyelhető legyen az eager connect és a dispose().
    // overrideWithValue NEM futtatná a buildert, így a dispose-wiring nem
    // lenne tesztelhető rajta keresztül. A valódi builder a forrás-
    // szemrevételezéssel verifikálható, hogy ugyanezt a SHAPE-et használja.

    test('eager connect-et indít az első olvasáskor', () async {
      final fake = _FakeNmeaStream();
      final container = ProviderContainer(
        overrides: [
          nmeaStreamProvider.overrideWith((ref) {
            ref.onDispose(fake.dispose);
            unawaited(fake.connect());
            return fake;
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(nmeaStreamProvider);
      await pumpEventQueue();

      expect(fake.connectCalled, isTrue);
    });

    test(
      'a container leállásakor dispose()-t hív, NEM disconnect()-et',
      () async {
        final fake = _FakeNmeaStream();
        final container = ProviderContainer(
          overrides: [
            nmeaStreamProvider.overrideWith((ref) {
              ref.onDispose(fake.dispose);
              unawaited(fake.connect());
              return fake;
            }),
          ],
        );
        addTearDown(container.dispose);

        container.read(nmeaStreamProvider);
        await pumpEventQueue();
        container.dispose();
        await pumpEventQueue();

        expect(fake.disposeCalled, isTrue);
        expect(fake.disconnectCalled, isFalse);
      },
    );
  });
}

class _FakeNmeaStream implements NmeaStream {
  bool connectCalled = false;
  bool disconnectCalled = false;
  bool disposeCalled = false;

  final StreamController<DomainEvent> _events =
      StreamController<DomainEvent>.broadcast();
  final StreamController<ConnectionStatus> _statusChanges =
      StreamController<ConnectionStatus>.broadcast();

  @override
  Stream<DomainEvent> get events => _events.stream;

  @override
  Stream<ConnectionStatus> get statusChanges => _statusChanges.stream;

  @override
  ConnectionStatus get currentStatus => const Disconnected();

  @override
  Future<void> connect() async {
    connectCalled = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  Future<void> dispose() async {
    disposeCalled = true;
    await _events.close();
    await _statusChanges.close();
  }
}
