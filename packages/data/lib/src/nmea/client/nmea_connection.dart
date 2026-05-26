/// A nyers byte-folyam absztrakciója a műszer-kapcsolat fölött. v1-ben csak
/// olvasunk a forrásból, ezért a teljes `dart:io` `Socket` helyett ennyi elég
/// — és így a TCP kliens hardver nélkül, fake kapcsolattal is tesztelhető
/// (kapcsolat-seam, ADR 0005).
abstract class NmeaConnection {
  /// A forrásból érkező nyers byte-ok; ezt vezeti a kliens a dekódoló
  /// pipeline-ba.
  Stream<List<int>> get bytes;

  /// A kapcsolat lezárása és az erőforrások felszabadítása.
  Future<void> close();
}

/// Kapcsolat-factory: a kliens ezen keresztül nyit kapcsolatot, így a
/// socket-réteg injektálható (éles `connectTcpSocket`, tesztben fake).
typedef NmeaConnector =
    Future<NmeaConnection> Function(String host, int port, {Duration timeout});
