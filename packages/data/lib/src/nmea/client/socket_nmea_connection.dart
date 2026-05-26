import 'dart:io';

import 'package:data/src/nmea/client/nmea_connection.dart';

/// A [NmeaConnection] éles, `dart:io` `Socket` fölötti megvalósítása. Csak a
/// bejövő byte-folyamot adja ki — a Vulcanra nem írunk vissza.
class _SocketNmeaConnection implements NmeaConnection {
  _SocketNmeaConnection(this._socket);

  final Socket _socket;

  @override
  Stream<List<int>> get bytes => _socket.cast<List<int>>();

  @override
  Future<void> close() async {
    await _socket.close();
    _socket.destroy();
  }
}

/// A default [NmeaConnector]: valódi TCP-kapcsolatot nyit a megadott
/// hosthoz/porthoz, [timeout] connect-időkorláttal. A TCP kliens ezt használja
/// éles futásban; tesztben fake connector lép a helyére.
Future<NmeaConnection> connectTcpSocket(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final socket = await Socket.connect(host, port, timeout: timeout);
  return _SocketNmeaConnection(socket);
}
