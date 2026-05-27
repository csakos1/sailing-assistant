import 'dart:async';

import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone/providers/nmea_stream_provider.dart';
import 'package:phone/providers/raw_nmea_lines_provider.dart';

void main() {
  group('rawNmeaLinesProvider', () {
    test('üresen marad, ha a forrás NEM RawNmeaLineSource', () async {
      final fake = _FakeNmeaStream();
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(container.read(rawNmeaLinesProvider), isEmpty);

      // Akkor sem szivárog be semmi, ha más csatornán adatot kapna a fake —
      // a forrás nem implementálja a RawNmeaLineSource interfészt.
      await pumpEventQueue();
      expect(container.read(rawNmeaLinesProvider), isEmpty);
    });

    test('a forrás nyers sorait a state-be gyűjti', () async {
      final fake = _FakeRawNmeaStream();
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // Aktív Riverpod-listener tartja életben az autoDispose providert,
      // hogy a build()-ben regisztrált rawLines-feliratkozás ne haljon meg
      // a read() után — különben a pushLine-ok a halott listener mellett
      // mennének el.
      final sub = container.listen(rawNmeaLinesProvider, (_, _) {});
      addTearDown(sub.close);

      fake
        ..pushLine(r'$WIMWV,54.0,R,4.0,N,A*16')
        ..pushLine(r'$WIMWV,90.1,T,8.1,N,A*14');
      await pumpEventQueue();

      expect(sub.read(), [
        r'$WIMWV,54.0,R,4.0,N,A*16',
        r'$WIMWV,90.1,T,8.1,N,A*14',
      ]);
    });

    test('ring-buffer: max 200 sor, a legrégebbiek esnek ki', () async {
      final fake = _FakeRawNmeaStream();
      final container = ProviderContainer(
        overrides: [nmeaStreamProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final sub = container.listen(rawNmeaLinesProvider, (_, _) {});
      addTearDown(sub.close);

      // 205 sor: az első 5 essen ki; a state hossza pontosan 200; az utolsó
      // elem a legutoljára beadott sor (line 204).
      for (var i = 0; i < 205; i++) {
        fake.pushLine('line $i');
      }
      await pumpEventQueue();

      final state = sub.read();
      expect(state, hasLength(200));
      expect(state.first, 'line 5');
      expect(state.last, 'line 204');
    });
  });
}

class _FakeNmeaStream implements NmeaStream {
  @override
  Stream<DomainEvent> get events => const Stream<DomainEvent>.empty();

  @override
  Stream<ConnectionStatus> get statusChanges =>
      const Stream<ConnectionStatus>.empty();

  @override
  ConnectionStatus get currentStatus => const Disconnected();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}

class _FakeRawNmeaStream extends _FakeNmeaStream implements RawNmeaLineSource {
  final StreamController<String> _rawLines =
      StreamController<String>.broadcast();

  void pushLine(String line) => _rawLines.add(line);

  @override
  Stream<String> get rawLines => _rawLines.stream;
}
