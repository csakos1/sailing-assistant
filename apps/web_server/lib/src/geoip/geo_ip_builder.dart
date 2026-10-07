import 'dart:io';

import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:web_server/src/geoip/dbip_city_row.dart';
import 'package:web_server/src/geoip/geo_ip_database.dart';

/// Egy sikeres építés: a sorok száma családonként.
typedef GeoIpBuildSummary = ({int ipv4Ranges, int ipv6Ranges});

/// Egy hibás CSV-sor: a sorszáma (1-től) és a hiba.
typedef GeoIpFormatError = ({int line, String reason});

/// A `geoip.sqlite` felépítése a DB-IP Lite City CSV [lines] soraiból
/// (ADR 0051 Addendum 6 N8).
///
/// Egy ideiglenes fájlba ír, egy tranzakcióban; csak a sikeres építés után
/// cseréli le az [outPath]-ot, így egy hibás forrás nem rontja el a
/// meglévő adatbázist. Az első hibás sornál leáll.
Future<Result<GeoIpBuildSummary, GeoIpFormatError>> buildGeoIpDatabase({
  required Stream<String> lines,
  required String outPath,
}) async {
  final partial = File('$outPath.partial');
  if (partial.existsSync()) partial.deleteSync();
  final database = sqlite3.open(partial.path);
  var isComplete = false;
  try {
    database
      ..execute('PRAGMA journal_mode = OFF')
      ..execute('PRAGMA synchronous = OFF')
      ..execute(geoIpSchema)
      ..execute('BEGIN');
    final result = await _insertAll(database, lines);
    if (result case Ok()) {
      database.execute('COMMIT');
      isComplete = true;
    }
    return result;
  } finally {
    database.close();
    try {
      if (isComplete) partial.renameSync(outPath);
    } finally {
      // Egy sikertelen átnevezés (pl. a `--out` könyvtár) után se maradjon
      // félkész fájl.
      if (partial.existsSync()) partial.deleteSync();
    }
  }
}

Future<Result<GeoIpBuildSummary, GeoIpFormatError>> _insertAll(
  Database database,
  Stream<String> lines,
) async {
  final insert = database.prepare(
    'INSERT INTO ip_ranges (family, range_start, range_end, country, city) '
    'VALUES (?, ?, ?, ?, ?)',
  );
  var lineNumber = 0;
  var ipv4Ranges = 0;
  var ipv6Ranges = 0;
  try {
    await for (final line in lines) {
      lineNumber++;
      if (line.trim().isEmpty) continue;
      final GeoIpRange range;
      switch (parseDbIpCityRow(line)) {
        case Err(:final error):
          return Err((line: lineNumber, reason: error));
        case Ok(:final value):
          range = value;
      }
      try {
        insert.execute([
          range.family,
          range.start,
          range.end,
          range.country,
          range.city,
        ]);
      } on SqliteException {
        return Err((line: lineNumber, reason: 'ismétlődő tartomány-kezdet'));
      }
      if (range.family == 4) {
        ipv4Ranges++;
      } else {
        ipv6Ranges++;
      }
    }
    return Ok((ipv4Ranges: ipv4Ranges, ipv6Ranges: ipv6Ranges));
  } finally {
    insert.close();
  }
}
