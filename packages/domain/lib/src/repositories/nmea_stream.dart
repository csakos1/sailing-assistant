import 'package:domain/src/repositories/connection_status.dart';
import 'package:domain/src/repositories/domain_event.dart';

/// A hajó műszeradatainak streamje, forrás-agnosztikusan.
///
/// A domain nem tudja, mi a forrás: v1-ben NMEA 0183 over TCP (Vulcan
/// WiFi), de e mögé kerül a replay-log, a mock és (v1.5+) egy YD RAW
/// (N2K) adapter is. Az implementáció a data rétegben él.
abstract class NmeaStream {
  /// A dekódolt domain-események folyama. A data réteg már lefordította
  /// a nyers mondatokat [DomainEvent]-re; a domain ezt fogyasztja.
  Stream<DomainEvent> get events;

  /// Csatlakozás a forráshoz.
  ///
  /// A hibát a [statusChanges] [ConnectionError]-eseménye jelzi, NEM
  /// dobott kivétel: vízen a stream nem állhat le egy exception miatt.
  Future<void> connect();

  /// Lekapcsolódás és az erőforrások felszabadítása.
  Future<void> disconnect();

  /// A pillanatnyi kapcsolat-állapot (szinkron lekérdezés).
  ConnectionStatus get currentStatus;

  /// A kapcsolat-állapot változásainak folyama a warning-rendszernek
  /// (11.) és a UI connection-badge-nek.
  Stream<ConnectionStatus> get statusChanges;
}
