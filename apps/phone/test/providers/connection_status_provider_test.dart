import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/connection_status_provider.dart';
import 'package:phone/providers/nmea_stream_provider.dart';

void main() {
  group('connectionStatusProvider', () {
    test('a kezdőértéket szinkron a currentStatus-ból seedeli', () {
      final fake = _FakeNmeaStream(initial: const Connecting());
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // A broadcast statusChanges NEM replay-eli az utolsót — ezért a
      // notifier szinkron a currentStatus-ból kell vegye a seedet, hogy a
      // badge azonnal helyes legyen (itt: Connecting), ne AsyncLoading-
      // villogás (ADR 0006).
      expect(container.read(connectionStatusProvider), const Connecting());
    });

    test('a statusChanges eseményekre frissíti a state-et', () async {
      final fake = _FakeNmeaStream(initial: const Connecting());
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // Aktív Riverpod-listener tartja életben az autoDispose providert,
      // hogy a build()-ben regisztrált statusChanges-feliratkozás ne haljon
      // meg — különben a teszt csak a rebuild-szeed értékét validálná, nem
      // azt, hogy a listener tényleg frissít.
      final sub = container.listen(connectionStatusProvider, (_, _) {});
      addTearDown(sub.close);

      fake.pushStatus(const Connected());
      await pumpEventQueue();

      expect(sub.read(), const Connected());
    });

    test('a ConnectionError üzenetet a state-en megőrzi', () async {
      final fake = _FakeNmeaStream(initial: const Connecting());
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(connectionStatusProvider, (_, _) {});
      addTearDown(sub.close);

      fake.pushStatus(const ConnectionError('Kapcsolat megszakadt'));
      await pumpEventQueue();

      final state = sub.read();
      expect(state, isA<ConnectionError>());
      expect((state as ConnectionError).message, 'Kapcsolat megszakadt');
    });
  });
}

class _FakeNmeaStream implements NmeaStream {
  _FakeNmeaStream({required ConnectionStatus initial}) : _current = initial;

  ConnectionStatus _current;
  final StreamController<ConnectionStatus> _statusChanges =
      StreamController<ConnectionStatus>.broadcast();

  void pushStatus(ConnectionStatus status) {
    _current = status;
    _statusChanges.add(status);
  }

  @override
  Stream<DomainEvent> get events => const Stream<DomainEvent>.empty();

  @override
  Stream<ConnectionStatus> get statusChanges => _statusChanges.stream;

  @override
  ConnectionStatus get currentStatus => _current;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}
