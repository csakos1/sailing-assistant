/// A `data` package publikus API-ja.
///
/// A kifelé látható felület két csoport:
///  - NMEA: a `Nmea0183TcpClient` (a `NmeaStream` domain-implementációja) és a
///    `RawNmeaLineSource` (debug raw-tap, ADR 0006);
///  - perzisztencia (Fázis 4, ADR 0008/0009): `AppDatabase`,
///    `RaceRepositoryImpl`, `TelemetryLoggerImpl` — az application-réteg
///    providerei számára.
///
/// A parser/pipeline `src/` alatt package-privát marad; a `NmeaStream` /
/// `ConnectionStatus` / `RaceRepository` / `TelemetryLogger` absztrakciók a
/// domainben élnek.
library;

export 'package:data/src/engine/race_engine.dart';
export 'package:data/src/engine/race_engine_snapshot.dart';
export 'package:data/src/nmea/client/nmea0183_tcp_client.dart';
export 'package:data/src/nmea/client/raw_nmea_line_source.dart';
export 'package:data/src/persistence/app_database.dart';
export 'package:data/src/persistence/repositories/race_repository_impl.dart';
export 'package:data/src/persistence/repositories/settings_repository_impl.dart';
export 'package:data/src/persistence/repositories/telemetry_logger_impl.dart';
