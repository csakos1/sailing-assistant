/// A `data` package publikus API-ja.
///
/// v1-ben a kifelé látható felület a `Nmea0183TcpClient` (a `NmeaStream`
/// domain-implementációja) és a `RawNmeaLineSource` (debug raw-tap, ADR
/// 0006); a parser/pipeline `src/` alatt package-privát marad, a
/// `NmeaStream`/`ConnectionStatus` pedig a domainben él.
library;

export 'package:data/src/nmea/client/nmea0183_tcp_client.dart';
export 'package:data/src/nmea/client/raw_nmea_line_source.dart';
