import 'dart:typed_data';

import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_server/src/geoip/geo_location.dart';
import 'package:web_server/src/geoip/ip_address_bytes.dart';

/// A `geoip.sqlite` egyetlen táblája (ADR 0051 Addendum 6 N7). Az `end`
/// SQL kulcsszó, ezért az oszlopok `range_start` és `range_end`.
const String geoIpSchema = '''
CREATE TABLE ip_ranges (
  family INTEGER NOT NULL,
  range_start BLOB NOT NULL,
  range_end BLOB NOT NULL,
  country TEXT,
  city TEXT,
  PRIMARY KEY (family, range_start)
)''';

const String _lookupSql =
    'SELECT range_end, country, city FROM ip_ranges '
    'WHERE family = ? AND range_start <= ? '
    'ORDER BY range_start DESC LIMIT 1';

/// A `geoip.sqlite` csak olvasva (Addendum 6 N9).
///
/// A keresés a családban a legnagyobb, a címnél nem nagyobb kezdetű sor; ha
/// a vége is lefedi a címet, az a hely. A BLOB-ok big-endian bájtjai miatt
/// az SQLite összevetése a címek sorrendje.
final class GeoIpDatabase {
  GeoIpDatabase._(this._database, this._lookup);

  /// A [path] fájl megnyitása csak olvasásra; hibánál (nincs fájl, nem
  /// SQLite, nincs `ip_ranges` tábla) a hiba szövege.
  static Result<GeoIpDatabase, String> open(String path) {
    Database? database;
    try {
      database = sqlite3.open(path, mode: OpenMode.readOnly);
      // A séma ellenőrzése: egy hiányzó tábla vagy oszlop már a
      // `prepare`-nél vagy az első keresésnél kiderül, nem belépéskor.
      final lookup = database.prepare(_lookupSql)..select([4, Uint8List(4)]);
      return Ok(GeoIpDatabase._(database, lookup));
    } on SqliteException catch (error) {
      database?.close();
      return Err(error.message);
    }
  }

  final Database _database;
  final PreparedStatement _lookup;

  /// Az [ip] cím helye; nem IP, nem nyilvános vagy nem lefedett címre
  /// ismeretlen.
  GeoLocation lookup(String ip) {
    final address = ipAddressBytesOf(ip, unwrapIpv4Mapped: true);
    if (address == null || !isPublicAddress(address)) return unknownLocation;
    final rows = _lookup.select([address.family, address.bytes]);
    if (rows.isEmpty) return unknownLocation;
    final row = rows.first;
    final end = row['range_end'];
    if (end is! Uint8List || compareAddressBytes(end, address.bytes) < 0) {
      return unknownLocation;
    }
    return (
      country: row['country'] as String?,
      city: row['city'] as String?,
    );
  }

  /// A fájl lezárása (a szerver leállásakor).
  void close() {
    _lookup.close();
    _database.close();
  }
}
