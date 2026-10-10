import 'package:data/data.dart';

/// Egy próba a gateway felé: `true`, ha a TCP-kapcsolat létrejött
/// (ADR 0054 D4). Nem dob: minden hiba „nincs hajó".
typedef GatewayProbe = Future<bool> Function();

/// Az éles [GatewayProbe]: a [host] gateway [port]-jára nyit egy kapcsolatot
/// a meglévő `NmeaConnection` seamen át ([connect], ADR 0005), [timeout]
/// időkorláttal, és azonnal bezárja. Adatot nem olvas.
GatewayProbe tcpGatewayProbe({
  required String host,
  required Duration timeout,
  int port = defaultNmeaGatewayPort,
  NmeaConnector connect = connectTcpSocket,
}) {
  return () async {
    final NmeaConnection connection;
    try {
      connection = await connect(host, port, timeout: timeout);
    } on Object {
      // SocketException (nincs útvonal, elutasítva, időtúllépés), vagy bármi
      // más: a próba sosem dob, a hiba egyszerűen „nincs hajó".
      return false;
    }
    try {
      await connection.close();
    } on Object {
      // A zárás hibája nem számít: a gateway elérhető volt.
    }
    return true;
  };
}
