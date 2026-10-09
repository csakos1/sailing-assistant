import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shared/shared.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:web_server/src/cli/missing_files.dart';
import 'package:web_server/src/geoip/geo_ip_builder.dart';

// A `geoip.sqlite` felépítése a DB-IP Lite City CSV-ből (ADR 0051
// Addendum 6 N8). A `.gz` fájlt maga bontja ki. A kimenet csak sikeres
// építés után cserélődik; egy formátumváltás az első hibás sornál
// leállítja (65), a sor számával; egy írhatatlan kimenet 73.
//
//   dart run web_server:build_geoip \
//     --csv dbip-city-lite-2026-10.csv.gz --out /var/lib/foretack/geoip.sqlite
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('csv', help: 'A DB-IP Lite City CSV (.csv vagy .csv.gz).')
    ..addOption('out', help: 'A létrehozandó geoip.sqlite útvonala.');

  final String csvPath;
  final String outPath;
  try {
    final options = parser.parse(arguments);
    csvPath =
        options.option('csv') ??
        (throw const FormatException('--csv: kötelező kapcsoló'));
    outPath =
        options.option('out') ??
        (throw const FormatException('--out: kötelező kapcsoló'));
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(parser.usage);
    exitCode = 64;
    return;
  }

  final missing = missingFileLines({'csv': csvPath});
  if (missing.isNotEmpty) {
    missing.forEach(stderr.writeln);
    exitCode = 66;
    return;
  }

  final bytes = File(csvPath).openRead();
  final decompressed = csvPath.endsWith('.gz')
      ? bytes.transform(gzip.decoder)
      : bytes;
  final lines = decompressed
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  try {
    switch (await buildGeoIpDatabase(lines: lines, outPath: outPath)) {
      case Ok(value: (:final ipv4Ranges, :final ipv6Ranges)):
        stdout.writeln(
          'Kész: $outPath — $ipv4Ranges IPv4- és $ipv6Ranges IPv6-tartomány.',
        );
      case Err(error: (:final line, :final reason)):
        stderr.writeln('Hibás sor ($line.): $reason');
        exitCode = 65;
    }
    // A régi fájl ezekben az esetekben is megmarad, a `.partial` törlődik.
  } on FormatException catch (error) {
    stderr.writeln('--csv: nem olvasható (gzip vagy UTF-8): ${error.message}');
    exitCode = 65;
  } on FileSystemException catch (error) {
    stderr.writeln('--out: nem írható: ${error.message} (${error.path})');
    exitCode = 73;
  } on SqliteException catch (error) {
    stderr.writeln('--out: az SQLite-fájl nem hozható létre: ${error.message}');
    exitCode = 73;
  }
}
