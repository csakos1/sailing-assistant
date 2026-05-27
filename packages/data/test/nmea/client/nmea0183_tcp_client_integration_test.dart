import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:data/src/nmea/client/nmea0183_tcp_client.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

// A parse-pipeline tesztekkel azonos, kézzel checksum-verifikált golden sor
// (apparent szél). A Vulcan CRLF-fel, időbélyeg-prefix nélkül küld.
const _apparentSentence = r'$WIMWV,54.0,R,4.0,N,A*16';

// Egy apparent sort ir a socketre es FLUSH-ol (a puszta add nem garantalja az
// idobeli kezbesitest a teszt alatt), majd [dropAfterWrite] eseten bont. A
// reconnect kozben eldobott peer write-hibajat elnyeli (best-effort write).
Future<void> _serveAndMaybeDrop(
  Socket socket, {
  required bool dropAfterWrite,
}) async {
  unawaited(socket.done.catchError((Object _) {}));
  socket.add(utf8.encode('$_apparentSentence\r\n'));
  try {
    await socket.flush();
    if (dropAfterWrite) {
      await socket.close();
    }
  } on Object {
    // a peer mar elment (reconnect kozben)
  }
}

void main() {
  group('Nmea0183TcpClient — loopback integráció', () {
    test(
      'valódi socketen átjönnek az események',
      () async {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen(
          (socket) =>
              unawaited(_serveAndMaybeDrop(socket, dropAfterWrite: false)),
        );

        final client = Nmea0183TcpClient(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          reconnectDelay: const Duration(milliseconds: 50),
        );
        addTearDown(client.dispose);

        // A broadcast events-re a connect() ELOTT iratkozunk fel.
        final firstWindEvent = expectLater(
          client.events,
          emitsThrough(isA<WindEvent>()),
        );

        await client.connect();
        await firstWindEvent;
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'valódi szakadás után újrakapcsolódik és újra emittál',
      () async {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        var connectionCount = 0;
        server.listen((socket) {
          final n = ++connectionCount;
          // Az elso kapcsolatot a flush utan bontjuk -> a kliens megkapja a
          // sort, EOF-ot kap, es ujrakapcsolodik.
          unawaited(_serveAndMaybeDrop(socket, dropAfterWrite: n == 1));
        });

        final client = Nmea0183TcpClient(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          reconnectDelay: const Duration(milliseconds: 50),
        );
        addTearDown(client.dispose);

        // Ket WindEvent: egy a szakadas elotti, egy a reconnect utani
        // kapcsolatrol. A feliratkozas a connect() elott tortenik.
        final twoWindEvents = client.events
            .where((event) => event is WindEvent)
            .take(2)
            .toList();

        await client.connect();
        final received = await twoWindEvents.timeout(
          const Duration(seconds: 5),
        );

        expect(received, hasLength(2));
        expect(connectionCount, greaterThanOrEqualTo(2));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'a loopback nyers sorai a rawLines streamen is megerkeznek',
      () async {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        server.listen(
          (socket) =>
              unawaited(_serveAndMaybeDrop(socket, dropAfterWrite: false)),
        );

        final client = Nmea0183TcpClient(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          reconnectDelay: const Duration(milliseconds: 50),
        );
        addTearDown(client.dispose);

        // A broadcast rawLines-ra a connect() ELOTT iratkozunk fel.
        final firstRawLine = expectLater(
          client.rawLines,
          emitsThrough(_apparentSentence),
        );

        await client.connect();
        await firstRawLine;
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      'a rawLines a valodi szakadast es reconnectet is fedi',
      () async {
        final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);

        var connectionCount = 0;
        server.listen((socket) {
          final n = ++connectionCount;
          unawaited(_serveAndMaybeDrop(socket, dropAfterWrite: n == 1));
        });

        final client = Nmea0183TcpClient(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          reconnectDelay: const Duration(milliseconds: 50),
        );
        addTearDown(client.dispose);

        // Ket azonos golden sort varunk: egyet a szakadas elotti, egyet
        // a reconnect utani kapcsolatrol. A long-lived rawLines miatt
        // egyetlen feliratkozas eleg.
        final twoRawLines = client.rawLines
            .where((line) => line == _apparentSentence)
            .take(2)
            .toList();

        await client.connect();
        final received = await twoRawLines.timeout(
          const Duration(seconds: 5),
        );

        expect(received, hasLength(2));
        expect(connectionCount, greaterThanOrEqualTo(2));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
