// A webes archívum végpontjai és a kliens-fejléc (ADR 0047 D9 + Addendum
// 1 A5, ADR 0048 D6). Egy helyen, hogy a szerver routere és a web kliense
// ne térhessen el egymástól.

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

/// Egy verseny eredménye: `PUT` (ADR 0048 D6).
String raceResultPath(String raceId) => '${racePath(raceId)}/result';

/// A kézi versenyek: `POST` létrehoz (ADR 0048 D6).
const String manualRacesPath = '/api/manual-races';

/// Egy kézi verseny: `PUT` ment, `DELETE` töröl (ADR 0048 D6).
String manualRacePath(String raceId) =>
    '$manualRacesPath/${Uri.encodeComponent(raceId)}';

/// A szezonok polár-összesítései: `GET` (ADR 0049 D12).
const String polarSeasonsPath = '/api/polar/seasons';

/// Egy szezon polár-táblázata: `GET` (ADR 0049 D12).
String polarSeasonPath(int year) => '$polarSeasonsPath/$year';

/// Egy verseny polár-blokkja: `GET` (ADR 0049 D12).
String racePolarPath(String raceId) => '${racePath(raceId)}/polar';

/// A teljes export tar.gz-ben: `GET` (ADR 0050 D8 + Addendum 3).
const String exportPath = '/api/export';
