// A webes archívum végpontjai és a kliens-fejléc (ADR 0047 D9 + Addendum 1
// A5). Egy helyen, hogy a szerver routere és a web kliense ne térhessen
// el egymástól.

/// A versenynapló: `GET`.
const String racesPath = '/api/races';

/// Az import: `POST`, multipart.
const String importsPath = '/api/imports';

/// Az import multipart-mezője a fő adatbázis-fájlnak (kötelező).
const String importDatabaseField = 'database';

/// Az import multipart-mezője a `-wal` fájlnak (opcionális).
const String importWalField = 'wal';

/// A CSRF-védelem fejléce: módosító kérésnél kötelező (D9).
const String clientHeaderName = 'X-Foretack-Client';

/// A web kliens által küldött érték a [clientHeaderName] fejlécben.
const String clientHeaderWebValue = 'web';

/// Egy verseny részletezője: `GET`.
String racePath(String raceId) => '$racesPath/${Uri.encodeComponent(raceId)}';

/// Egy verseny eredmény-adatai: `PUT`.
String raceAnnotationPath(String raceId) => '${racePath(raceId)}/annotation';
