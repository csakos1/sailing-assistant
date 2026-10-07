import 'dart:typed_data';

import 'package:shared/shared.dart';
import 'package:web_server/src/geoip/csv_line.dart';
import 'package:web_server/src/geoip/ip_address_bytes.dart';

/// Egy IP-tartomány a helyével, a `geoip.sqlite` egy sora (ADR 0051
/// Addendum 6 N7).
typedef GeoIpRange = ({
  int family,
  Uint8List start,
  Uint8List end,
  String? country,
  String? city,
});

const int _columnCount = 8;

/// A DB-IP Lite City CSV egy sora (Addendum 6 N8): `ip_start, ip_end,
/// continent, country, stateprov, city, latitude, longitude`, fejléc
/// nélkül. A `ZZ` (fenntartott) és az üres ország, illetve az üres város
/// ismeretlen.
///
/// Hibánál a hiba rövid leírása: más oszlopszám, érvénytelen cím, vegyes
/// család vagy fordított tartomány.
Result<GeoIpRange, String> parseDbIpCityRow(String line) {
  final fields = parseCsvLine(line);
  if (fields == null) return const Err('hibás idézőjelezés');
  if (fields.length != _columnCount) {
    return Err('$_columnCount oszlop helyett ${fields.length}');
  }
  final start = ipAddressBytesOf(fields[0]);
  final end = ipAddressBytesOf(fields[1]);
  if (start == null || end == null) return const Err('érvénytelen IP-cím');
  if (start.family != end.family) return const Err('vegyes IPv4/IPv6');
  if (compareAddressBytes(start.bytes, end.bytes) > 0) {
    return const Err('a tartomány vége az eleje előtt van');
  }
  final country = fields[3].trim();
  final city = fields[5].trim();
  return Ok((
    family: start.family,
    start: start.bytes,
    end: end.bytes,
    country: country.isEmpty || country == 'ZZ' ? null : country,
    city: city.isEmpty ? null : city,
  ));
}
