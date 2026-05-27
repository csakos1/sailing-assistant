import 'dart:async';
import 'dart:convert';

import 'package:data/src/nmea/client/nmea0183_tcp_client.dart';
import 'package:data/src/nmea/client/nmea_connection.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Teszt-kapcsolat: a byte-folyamot a teszt vezérli. A [drop] szimulál
/// szakadást (a stream lezárása → `done`), a [close] a kliens teardownját
/// jelzi. Egy-feliratkozós controller — a kliens egyszer listenel rá.
class _FakeConnection implements NmeaConnection {
  final StreamController<List<int>> _controller = StreamController<List<int>>();

  /// true, miután a kliens lezárta a kapcsolatot.
  bool isClosed = false;

  @override
  Stream<List<int>> get bytes => _controller.stream;

  @override
  Future<void> close() async {
    isClosed = true;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  /// Egy vagy több 0183 sort ad a folyamba (egy utf8 chunként, `\n`-nel).
  void emit(List<String> lines) {
    _controller.add(utf8.encode('${lines.join('\n')}\n'));
  }

  /// Szakadás: a forrás-stream lezárása (`done`), mintha a Vulcan elejtené.
  Future<void> drop() => _controller.close();
}

/// Scriptelt connector: minden hívás a következő scriptelt elemet adja —
/// `null` → csatlakozási hiba (dobás), egyébként a megadott kapcsolat. A
/// [calls] számolja a hívásokat (a reconnect ellenőrzéséhez).
class _ScriptedConnector {
  _ScriptedConnector(this._script);

  final List<_FakeConnection?> _script;

  int calls = 0;

  Future<NmeaConnection> connect(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final index = calls;
    calls++;
    final entry = index < _script.length ? _script[index] : _script.last;
    if (entry == null) {
      throw Exception('teszt: a csatlakozás elutasítva');
    }
    return entry;
  }
}

void main() {
  // Golden 0183 sorok (valós '*' checksum; ugyanazok, mint a pipeline-tesztben).
  const apparent = r'$WIMWV,54.0,R,4.0,N,A*16';
  const trueWind = r'$WIMWV,90.1,T,8.1,N,A*14';

  group('Nmea0183TcpClient kapcsolat-életciklus', () {
    test('connect() Connecting majd Connected státuszt ad', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final statuses = <ConnectionStatus>[];
      final sub = client.statusChanges.listen(statuses.add);

      await client.connect();
      await pumpEventQueue();

      expect(statuses, [isA<Connecting>(), isA<Connected>()]);
      expect(client.currentStatus, isA<Connected>());
      expect(connector.calls, 1);

      await sub.cancel();
      await client.dispose();
    });

    test(
      'connect() idempotens — kétszer hívva egy kapcsolat jön létre',
      () async {
        final connector = _ScriptedConnector([_FakeConnection()]);
        final client = Nmea0183TcpClient(
          connector: connector.connect,
          reconnectDelay: Duration.zero,
        );

        await client.connect();
        await client.connect();
        await pumpEventQueue();

        expect(connector.calls, 1);

        await client.dispose();
      },
    );

    test(
      'disconnect() Disconnected-et ad és leállítja a reconnectet',
      () async {
        final conn = _FakeConnection();
        final connector = _ScriptedConnector([conn]);
        final client = Nmea0183TcpClient(
          connector: connector.connect,
          reconnectDelay: Duration.zero,
        );
        final statuses = <ConnectionStatus>[];
        final sub = client.statusChanges.listen(statuses.add);

        await client.connect();
        await pumpEventQueue();
        await client.disconnect();
        await pumpEventQueue();

        expect(statuses.last, isA<Disconnected>());
        expect(conn.isClosed, isTrue);
        expect(connector.calls, 1);

        await sub.cancel();
        await client.dispose();
      },
    );
  });

  group('Nmea0183TcpClient adatfolyam', () {
    test('a beérkező mondatból DomainEvent lesz az events streamen', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final events = <DomainEvent>[];
      final sub = client.events.listen(events.add);

      await client.connect();
      await pumpEventQueue();
      conn.emit([apparent]);
      await pumpEventQueue();

      expect(events, hasLength(1));
      expect(events.single, isA<WindEvent>());

      await sub.cancel();
      await client.dispose();
    });

    test('az events broadcast — több feliratkozó is megkapja', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final first = <DomainEvent>[];
      final second = <DomainEvent>[];
      final subA = client.events.listen(first.add);
      final subB = client.events.listen(second.add);

      await client.connect();
      await pumpEventQueue();
      conn.emit([apparent]);
      await pumpEventQueue();

      expect(first, hasLength(1));
      expect(second, hasLength(1));

      await subA.cancel();
      await subB.cancel();
      await client.dispose();
    });
  });

  group('Nmea0183TcpClient reconnect', () {
    test('sikertelen csatlakozás után újrapróbál', () async {
      // Az első hívás dob, a második sikerül.
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([null, conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final statuses = <ConnectionStatus>[];
      final sub = client.statusChanges.listen(statuses.add);

      await client.connect();
      await pumpEventQueue();

      expect(statuses, [
        isA<Connecting>(),
        isA<ConnectionError>(),
        isA<Connecting>(),
        isA<Connected>(),
      ]);
      expect(connector.calls, 2);

      await sub.cancel();
      await client.dispose();
    });

    test('szakadás után újracsatlakozik és újra ad eseményt', () async {
      final conn1 = _FakeConnection();
      final conn2 = _FakeConnection();
      final connector = _ScriptedConnector([conn1, conn2]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final events = <DomainEvent>[];
      final statuses = <ConnectionStatus>[];
      final subE = client.events.listen(events.add);
      final subS = client.statusChanges.listen(statuses.add);

      await client.connect();
      await pumpEventQueue();
      conn1.emit([apparent]);
      await pumpEventQueue();
      await conn1.drop();
      await pumpEventQueue();
      conn2.emit([apparent]);
      await pumpEventQueue();

      expect(connector.calls, 2);
      expect(events, hasLength(2));
      expect(events.every((e) => e is WindEvent), isTrue);
      expect(statuses, [
        isA<Connecting>(),
        isA<Connected>(),
        isA<ConnectionError>(),
        isA<Connecting>(),
        isA<Connected>(),
      ]);

      await subE.cancel();
      await subS.cancel();
      await client.dispose();
    });

    test(
      'a szél-állapot túléli a reconnectet (a pipeline újrahasznosul)',
      () async {
        final conn1 = _FakeConnection();
        final conn2 = _FakeConnection();
        final connector = _ScriptedConnector([conn1, conn2]);
        final client = Nmea0183TcpClient(
          connector: connector.connect,
          reconnectDelay: Duration.zero,
        );
        final winds = <WindEvent>[];
        final sub = client.events.listen((event) {
          if (event is WindEvent) {
            winds.add(event);
          }
        });

        await client.connect();
        await pumpEventQueue();
        // Első kapcsolat: apparent + true → a 2. snapshot már hordozza a true-t.
        conn1.emit([apparent, trueWind]);
        await pumpEventQueue();
        await conn1.drop();
        await pumpEventQueue();
        // Reconnect után CSAK apparent: ha a pipeline (és a WindAggregator)
        // újrahasznosult, a korábbi true szél carry-forwarddal megjelenik.
        conn2.emit([apparent]);
        await pumpEventQueue();

        expect(winds, hasLength(3));
        expect(winds.last.data.hasTrueWind, isTrue);

        await sub.cancel();
        await client.dispose();
      },
    );
  });

  group('Nmea0183TcpClient nyers sor-tap', () {
    test('a bejövő mondatot nyers sorként is kiadja', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final rawLines = <String>[];
      final sub = client.rawLines.listen(rawLines.add);

      await client.connect();
      await pumpEventQueue();
      conn.emit([apparent]);
      await pumpEventQueue();

      expect(rawLines, [apparent]);

      await sub.cancel();
      await client.dispose();
    });

    test('a rawLines és az events ugyanazt a kapcsolatot fedi le', () async {
      // A kettős feliratkozás timing-buktatóját ezzel fogjuk ki: ugyanaz a
      // sor mindkét ágra az ELSŐ bájttól megérkezik (a broadcast nem
      // pufferel, de a socket I/O az event-loopból, a microtask-drain UTÁN
      // jön — ld. ADR 0006).
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final events = <DomainEvent>[];
      final rawLines = <String>[];
      final subE = client.events.listen(events.add);
      final subR = client.rawLines.listen(rawLines.add);

      await client.connect();
      await pumpEventQueue();
      conn.emit([apparent]);
      await pumpEventQueue();

      expect(events, hasLength(1));
      expect(events.single, isA<WindEvent>());
      expect(rawLines, [apparent]);

      await subE.cancel();
      await subR.cancel();
      await client.dispose();
    });

    test('a rawLines broadcast — több feliratkozó is megkapja', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final first = <String>[];
      final second = <String>[];
      final subA = client.rawLines.listen(first.add);
      final subB = client.rawLines.listen(second.add);

      await client.connect();
      await pumpEventQueue();
      conn.emit([apparent]);
      await pumpEventQueue();

      expect(first, [apparent]);
      expect(second, [apparent]);

      await subA.cancel();
      await subB.cancel();
      await client.dispose();
    });

    test('a rawLines stream túléli a reconnectet', () async {
      // A long-lived _rawLines controller miatt a per-kapcsolat rawSub
      // cancellje (finally) NEM zárja le a streamet: a következő kapcsolat
      // sorai ugyanahhoz a fogyasztóhoz érkeznek.
      final conn1 = _FakeConnection();
      final conn2 = _FakeConnection();
      final connector = _ScriptedConnector([conn1, conn2]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      final rawLines = <String>[];
      final sub = client.rawLines.listen(rawLines.add);

      await client.connect();
      await pumpEventQueue();
      conn1.emit([apparent]);
      await pumpEventQueue();
      await conn1.drop();
      await pumpEventQueue();
      conn2.emit([trueWind]);
      await pumpEventQueue();

      expect(rawLines, [apparent, trueWind]);

      await sub.cancel();
      await client.dispose();
    });

    test('a dispose() lezárja a rawLines streamet (onDone fut)', () async {
      final conn = _FakeConnection();
      final connector = _ScriptedConnector([conn]);
      final client = Nmea0183TcpClient(
        connector: connector.connect,
        reconnectDelay: Duration.zero,
      );
      var doneReached = false;
      final sub = client.rawLines.listen(
        (_) {},
        onDone: () => doneReached = true,
      );

      await client.connect();
      await pumpEventQueue();
      await client.dispose();
      await pumpEventQueue();

      expect(doneReached, isTrue);

      await sub.cancel();
    });
  });
}
